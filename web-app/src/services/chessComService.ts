import { Chess } from 'chess.js';
import { TacticalPuzzle } from '../data/chessContent';
import { findBestLine, evaluatePosition } from '../utils/chessSearch';

export interface ChessComGame {
  url: string;
  pgn: string;
  time_control: string;
  end_time: number;
  rated: boolean;
  white: { username: string; rating: number; result: string };
  black: { username: string; rating: number; result: string };
}

export interface ChessComProfile {
  username: string;
  avatar?: string;
  title?: string;
  country?: string;
  status?: string;
}

/**
 * Fetches player public profile from Chess.com
 */
export async function fetchChessComProfile(username: string): Promise<ChessComProfile | null> {
  try {
    const cleanUser = username.trim().toLowerCase();
    const res = await fetch(`https://api.chess.com/pub/player/${cleanUser}`);
    if (!res.ok) return null;
    return await res.json();
  } catch (err) {
    console.error('Error fetching Chess.com profile:', err);
    return null;
  }
}

export interface FetchGamesOptions {
  limit?: number;
  timeControl?: 'all' | 'rapid' | 'blitz' | 'bullet' | 'daily';
  ratedOnly?: boolean;
  color?: 'all' | 'white' | 'black';
  startDate?: string; // YYYY-MM-DD or ISO string
  endDate?: string;   // YYYY-MM-DD or ISO string
}

/**
 * Fetches games from Chess.com public archives across months with configurable filters
 */
// In-memory cache for fetched games to make subsequent loads instant
const gamesCache = new Map<string, { timestamp: number; games: ChessComGame[] }>();
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes cache

export async function fetchRecentChessComGames(
  username: string,
  options: FetchGamesOptions = {}
): Promise<ChessComGame[]> {
  try {
    const cleanUser = username.trim().toLowerCase();
    const limit = options.limit ?? 100;
    const timeFilter = options.timeControl ?? 'all';
    const ratedOnly = options.ratedOnly ?? false;
    const colorFilter = options.color ?? 'all';

    const startTimestamp = options.startDate ? new Date(options.startDate).getTime() / 1000 : null;
    const endTimestamp = options.endDate ? (new Date(options.endDate).getTime() / 1000) + 86400 : null; // include whole end day

    // Check memory cache
    const cacheKey = `${cleanUser}_${limit}_${timeFilter}_${ratedOnly}_${colorFilter}_${options.startDate || ''}_${options.endDate || ''}`;
    const cached = gamesCache.get(cacheKey);
    if (cached && Date.now() - cached.timestamp < CACHE_TTL_MS) {
      return cached.games;
    }

    // Check sessionStorage cache for instant load across tabs/refreshes
    try {
      const sessionKey = `chessfr_games_${cacheKey}`;
      const sessionData = sessionStorage.getItem(sessionKey);
      if (sessionData) {
        const parsed = JSON.parse(sessionData);
        if (parsed.timestamp && Date.now() - parsed.timestamp < CACHE_TTL_MS && Array.isArray(parsed.games)) {
          gamesCache.set(cacheKey, { timestamp: parsed.timestamp, games: parsed.games });
          return parsed.games;
        }
      }
    } catch (e) {
      // Ignore storage errors
    }

    // Fetch full archive list
    const archivesRes = await fetch(`https://api.chess.com/pub/player/${cleanUser}/games/archives`);
    let archiveUrls: string[] = [];

    if (archivesRes.ok) {
      const archivesData = await archivesRes.json();
      archiveUrls = (archivesData.archives || []).reverse(); // Newest months first
    } else {
      // Fallback to current and previous month
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      archiveUrls = [`https://api.chess.com/pub/player/${cleanUser}/games/${year}/${month}`];
    }

    const collected: ChessComGame[] = [];

    // Process archives in parallel batches of 3 to maximize network throughput without hitting rate limits
    const BATCH_SIZE = 3;
    for (let i = 0; i < archiveUrls.length && collected.length < limit; i += BATCH_SIZE) {
      const batchUrls = archiveUrls.slice(i, i + BATCH_SIZE);
      const responses = await Promise.allSettled(
        batchUrls.map((url) => fetch(url).then((res) => (res.ok ? res.json() : null)))
      );

      for (const res of responses) {
        if (res.status !== 'fulfilled' || !res.value) continue;
        const monthGames: ChessComGame[] = (res.value.games || []).reverse(); // newest first within month

        for (const g of monthGames) {
          if (collected.length >= limit) break;

          // Date range filter
          if (startTimestamp !== null && g.end_time < startTimestamp) continue;
          if (endTimestamp !== null && g.end_time > endTimestamp) continue;

          // Color filter
          if (colorFilter !== 'all') {
            const isWhite = g.white.username.toLowerCase() === cleanUser;
            if (colorFilter === 'white' && !isWhite) continue;
            if (colorFilter === 'black' && isWhite) continue;
          }

          // Time control filter
          if (timeFilter !== 'all') {
            const timeClass = (g as any).time_class || '';
            if (timeClass.toLowerCase() !== timeFilter.toLowerCase()) continue;
          }

          // Rated filter
          if (ratedOnly && !g.rated) continue;

          collected.push(g);
        }
        if (collected.length >= limit) break;
      }
    }

    // Save to caches
    gamesCache.set(cacheKey, { timestamp: Date.now(), games: collected });
    try {
      sessionStorage.setItem(`chessfr_games_${cacheKey}`, JSON.stringify({ timestamp: Date.now(), games: collected }));
    } catch (e) {
      // Ignore quota exceeded
    }

    return collected;
  } catch (err) {
    console.error('Error fetching Chess.com games:', err);
    return [];
  }
}

/**
 * Extracts blunders that occurred in WON, DRAWN, and LOST games!
 * Replaces traditional generic puzzle pools with actual mistakes made in games.
 */
export function extractBlundersFromGames(
  games: ChessComGame[],
  targetUsername: string
): TacticalPuzzle[] {
  const puzzles: TacticalPuzzle[] = [];
  const cleanTarget = targetUsername.trim().toLowerCase();

  for (const game of games) {
    if (!game.pgn) continue;

    try {
      const isWhite = game.white.username.toLowerCase() === cleanTarget;
      const playerColor: 'w' | 'b' = isWhite ? 'w' : 'b';
      const myResult = isWhite ? game.white.result : game.black.result;
      const opponentName = isWhite ? game.black.username : game.white.username;
      const opponentRating = isWhite ? game.black.rating : game.white.rating;
      const gameDateStr = new Date(game.end_time * 1000).toLocaleDateString();

      const gameOutcome: 'win' | 'loss' | 'draw' =
        myResult === 'win'
          ? 'win'
          : ['agreed', 'repetition', 'stalemate', 'timevsinsufficient', 'insufficient'].includes(myResult)
          ? 'draw'
          : 'loss';

      const chess = new Chess();
      chess.loadPgn(game.pgn);
      const history = chess.history({ verbose: true });
      if (history.length < 8) continue;

      // Replay move by move and identify player moves that caused centipawn drop (blunders)
      const replayChess = new Chess();
      let lastEval = evaluatePosition(replayChess);

      for (let i = 0; i < history.length; i++) {
        const move = history[i];
        const isPlayerTurn = (i % 2 === 0 && isWhite) || (i % 2 === 1 && !isWhite);

        if (isPlayerTurn) {
          const preFen = replayChess.fen();
          replayChess.move(move);
          const postEval = evaluatePosition(replayChess);
          
          // Drop for white: lastEval - postEval; Drop for black: postEval - lastEval
          const evalDrop = isWhite ? (lastEval - postEval) : (postEval - lastEval);

          // If blunder detected (eval drop >= 180 cp or clear tactical mistake in middlegame)
          if (evalDrop >= 180 && i >= 6) {
            // Find 3-move optimal continuation from preFen
            const searchChess = new Chess(preFen);
            const bestLine = findBestLine(searchChess, 3);

            if (bestLine && bestLine.line.length > 0) {
              const outcomeLabel = gameOutcome === 'win' ? 'Won Game' : (gameOutcome === 'draw' ? 'Drawn Game' : 'Lost Game');
              
              puzzles.push({
                id: `blunder-${game.end_time}-${i}`,
                title: `Blunder Recovery (${outcomeLabel} vs ${opponentName})`,
                theme: gameOutcome === 'win' ? 'Weakness in Won Game' : 'Personal Blunder Recovery',
                rating: opponentRating || 1350,
                description: `In your ${outcomeLabel} vs ${opponentName} on ${gameDateStr}, you played ${move.san} (a blunder). Fix this weakness! What is the three move answer to this position?`,
                fen: preFen,
                solutionUci: bestLine.line,
                solutionSan: bestLine.lineSan,
                playerColor,
                explanation: `In your game you played ${move.san}. Instead, ${bestLine.lineSan.join(' ')} stabilizes the position and maintains a +${((bestLine.eval) / 100).toFixed(1)} evaluation.`,
                isThreeMovePlan: true,
                playedBlunder: move.san,
                opponent: opponentName,
                gameDate: gameDateStr,
                gameOutcome,
                gameUrl: game.url
              });
              // Only 1 major blunder per game to keep drills diverse
              break;
            }
          }
          lastEval = postEval;
        } else {
          replayChess.move(move);
          lastEval = evaluatePosition(replayChess);
        }
      }
    } catch (e) {
      console.warn('Error extracting blunder from game:', e);
    }
  }

  return puzzles;
}

/**
 * Generates scenarios for positions that occur frequently across the player's game history
 * with the exact prompt: "Here is a position you are likely to see based on your games: what is the three move answer to this position?"
 */
export function generateCommonPositionalScenarios(
  games: ChessComGame[],
  targetUsername: string
): TacticalPuzzle[] {
  const cleanTarget = targetUsername.trim().toLowerCase();
  // Map FEN skeleton (first 4 fields: pieces, turn, castling, ep) to occurrences
  const fenOccurrences: Map<string, { count: number; sampleFen: string; turn: 'w' | 'b'; gameUrl?: string }> = new Map();

  for (const game of games) {
    if (!game.pgn) continue;
    try {
      const isWhite = game.white.username.toLowerCase() === cleanTarget;
      const playerColor: 'w' | 'b' = isWhite ? 'w' : 'b';

      const chess = new Chess();
      chess.loadPgn(game.pgn);
      const history = chess.history({ verbose: true });

      // Sample key middlegame tabiya points (moves 6-16)
      const replayChess = new Chess();
      for (let i = 0; i < Math.min(history.length, 18); i++) {
        replayChess.move(history[i]);
        const isPlayerTurn = replayChess.turn() === playerColor;

        if (isPlayerTurn && i >= 6) {
          const currentFen = replayChess.fen();
          // Position key: piece placement and turn
          const key = currentFen.split(' ').slice(0, 2).join(' ');
          const existing = fenOccurrences.get(key);
          if (existing) {
            existing.count += 1;
          } else {
            fenOccurrences.set(key, {
              count: 1,
              sampleFen: currentFen,
              turn: playerColor,
              gameUrl: game.url
            });
          }
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  // Sort by highest occurrence count
  const sortedPositions = Array.from(fenOccurrences.values())
    .sort((a, b) => b.count - a.count)
    .slice(0, 5);

  const scenarioPuzzles: TacticalPuzzle[] = [];

  for (let idx = 0; idx < sortedPositions.length; idx++) {
    const item = sortedPositions[idx];
    try {
      const searchChess = new Chess(item.sampleFen);
      const bestLine = findBestLine(searchChess, 3);

      if (bestLine && bestLine.line.length > 0) {
        scenarioPuzzles.push({
          id: `common-pos-${idx}-${Date.now()}`,
          title: `Positional Plan: High-Frequency Motif #${idx + 1}`,
          theme: 'Most Common Game Scenario',
          rating: 1400,
          description: 'Here is a position you are likely to see based on your games: what is the three move answer to this position?',
          fen: item.sampleFen,
          solutionUci: bestLine.line,
          solutionSan: bestLine.lineSan,
          playerColor: item.turn,
          explanation: `This critical position occurred in ${item.count} of your games. The optimal 3-move plan sequence is ${bestLine.lineSan.join(' ')}.`,
          isThreeMovePlan: true,
          frequencyScore: item.count,
          gameUrl: item.gameUrl
        });
      }
    } catch (e) {
      console.warn('Failed to calculate 3-move plan for common position:', e);
    }
  }

  return scenarioPuzzles;
}

/**
 * Generates custom pattern puzzles derived directly from the player's most challenging variations (loss games with thematic leaks)
 */
export function generateChallengingVariationPuzzles(
  challengingOpenings: Array<{
    name: string;
    eco: string;
    playedAs: 'White' | 'Black' | 'Both';
    winRate: number;
    criticalFen?: string;
    challengingPattern?: {
      theme: string;
      problemDescription: string;
      actionableAdvice: string;
      solutionSan: string[];
      solutionUci: string[];
    };
  }>
): TacticalPuzzle[] {
  const challengingPuzzles: TacticalPuzzle[] = [];

  for (let idx = 0; idx < challengingOpenings.length; idx++) {
    const op = challengingOpenings[idx];
    if (!op.criticalFen || !op.challengingPattern) continue;

    const pattern = op.challengingPattern;
    const playerColor: 'w' | 'b' = op.playedAs === 'Black' ? 'b' : 'w';

    challengingPuzzles.push({
      id: `challenging-var-${op.eco}-${idx}-${Date.now()}`,
      title: `Challenging Variation: ${op.name}`,
      theme: pattern.theme || 'Challenging Variation Pattern',
      rating: 1450,
      description: `In this recurring loss variation (${op.winRate}% win rate), you faced: ${pattern.problemDescription}. What is the correct 3-move response to overcome or avoid this trap?`,
      fen: op.criticalFen,
      solutionUci: pattern.solutionUci,
      solutionSan: pattern.solutionSan,
      playerColor,
      explanation: pattern.actionableAdvice || `Optimal 3-move continuation is ${pattern.solutionSan.join(' ')}.`,
      isThreeMovePlan: true
    });
  }

  return challengingPuzzles;
}

/**
 * Backward compatibility helper
 */
export function generatePuzzleFromGame(
  game: ChessComGame,
  targetUsername: string
): TacticalPuzzle | null {
  const blunders = extractBlundersFromGames([game], targetUsername);
  return blunders.length > 0 ? blunders[0] : null;
}

