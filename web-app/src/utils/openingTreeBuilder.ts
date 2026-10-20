import { Chess } from 'chess.js';
import { ChessComGame } from '../services/chessComService';

export interface TreeMoveStats {
  san: string;
  uci: string;
  gamesCount: number;
  frequency: number; // percentage of games this move was chosen
  wins: number;
  draws: number;
  losses: number;
  winRate: number; // 0 - 100
  drawRate: number; // 0 - 100
  lossRate: number; // 0 - 100
  avgOpponentRating: number;
  nextFen: string;
}

export interface TreePositionNode {
  fen: string;
  totalGames: number;
  moves: TreeMoveStats[];
}

export interface OpeningTree {
  // Keyed by normalized FEN (pieces + turn + castling)
  nodes: Map<string, TreePositionNode>;
  totalGamesAnalyzed: number;
  color: 'white' | 'black';
}

function normalizeFen(fen: string): string {
  // Use first 3 parts of FEN (placement, active color, castling) for robust transposition matching
  const parts = fen.split(' ');
  return parts.slice(0, 3).join(' ');
}

/**
 * Builds an interactive Opening Tree from a player's games (like openingtree.com)
 */
export function buildOpeningTree(
  games: ChessComGame[],
  targetUsername: string,
  colorFilter: 'white' | 'black' = 'white'
): OpeningTree {
  const cleanTarget = targetUsername.trim().toLowerCase();
  const nodes = new Map<string, Map<string, {
    san: string;
    uci: string;
    gamesCount: number;
    wins: number;
    draws: number;
    losses: number;
    opponentRatingSum: number;
    nextFen: string;
  }>>();

  let gamesCount = 0;

  for (const game of games) {
    if (!game.pgn) continue;

    const isWhite = game.white.username.toLowerCase() === cleanTarget;
    if (colorFilter === 'white' && !isWhite) continue;
    if (colorFilter === 'black' && isWhite) continue;

    gamesCount++;

    const myResult = isWhite ? game.white.result : game.black.result;
    const oppRating = isWhite ? (game.black.rating || 1200) : (game.white.rating || 1200);

    const isWin = myResult === 'win';
    const isDraw = ['agreed', 'repetition', 'stalemate', 'timevsinsufficient', 'insufficient'].includes(myResult);
    const isLoss = !isWin && !isDraw;

    try {
      const chess = new Chess();
      chess.loadPgn(game.pgn);
      const history = chess.history({ verbose: true });

      const replayChess = new Chess();
      // Record up to 24 plies (12 full moves) of opening tree
      const maxPlies = Math.min(history.length, 24);

      for (let i = 0; i < maxPlies; i++) {
        const move = history[i];
        const currentNormFen = normalizeFen(replayChess.fen());

        if (!nodes.has(currentNormFen)) {
          nodes.set(currentNormFen, new Map());
        }

        const moveMap = nodes.get(currentNormFen)!;
        const uci = `${move.from}${move.to}`;
        const existing = moveMap.get(move.san) || {
          san: move.san,
          uci,
          gamesCount: 0,
          wins: 0,
          draws: 0,
          losses: 0,
          opponentRatingSum: 0,
          nextFen: ''
        };

        existing.gamesCount += 1;
        existing.opponentRatingSum += oppRating;
        if (isWin) existing.wins += 1;
        else if (isDraw) existing.draws += 1;
        else if (isLoss) existing.losses += 1;

        replayChess.move(move);
        existing.nextFen = replayChess.fen();

        moveMap.set(move.san, existing);
      }
    } catch (e) {
      // Ignore PGN parse error
    }
  }

  // Convert raw maps to structured OpeningTree representation
  const finalNodes = new Map<string, TreePositionNode>();

  nodes.forEach((movesMap, normFen) => {
    let totalPositionGames = 0;
    movesMap.forEach((m) => {
      totalPositionGames += m.gamesCount;
    });

    const moveStats: TreeMoveStats[] = [];

    movesMap.forEach((m) => {
      const winRate = m.gamesCount > 0 ? Math.round((m.wins / m.gamesCount) * 100) : 0;
      const drawRate = m.gamesCount > 0 ? Math.round((m.draws / m.gamesCount) * 100) : 0;
      const lossRate = m.gamesCount > 0 ? Math.max(0, 100 - winRate - drawRate) : 0;
      const frequency = totalPositionGames > 0 ? Math.round((m.gamesCount / totalPositionGames) * 100) : 0;
      const avgOpponentRating = m.gamesCount > 0 ? Math.round(m.opponentRatingSum / m.gamesCount) : 1200;

      moveStats.push({
        san: m.san,
        uci: m.uci,
        gamesCount: m.gamesCount,
        frequency,
        wins: m.wins,
        draws: m.draws,
        losses: m.losses,
        winRate,
        drawRate,
        lossRate,
        avgOpponentRating,
        nextFen: m.nextFen
      });
    });

    // Sort moves by highest number of games played
    moveStats.sort((a, b) => b.gamesCount - a.gamesCount);

    finalNodes.set(normFen, {
      fen: normFen,
      totalGames: totalPositionGames,
      moves: moveStats
    });
  });

  return {
    nodes: finalNodes,
    totalGamesAnalyzed: gamesCount,
    color: colorFilter
  };
}

/**
 * Look up moves in the tree for a specific FEN
 */
export function getTreeMovesForFen(tree: OpeningTree | null, fen: string): TreeMoveStats[] {
  if (!tree) return [];
  const norm = normalizeFen(fen);
  const node = tree.nodes.get(norm);
  return node ? node.moves : [];
}
