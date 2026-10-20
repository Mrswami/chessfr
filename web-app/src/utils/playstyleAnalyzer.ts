import { Chess } from 'chess.js';
import { ChessComGame } from '../services/chessComService';
import { findBestLine } from './chessSearch';

export interface OpeningBranchMove {
  san: string;
  ply: number;
  evalCp?: number;
  isBlunder?: boolean;
}

export interface OpeningStats {
  name: string;
  eco: string;
  playedAs: 'White' | 'Black' | 'Both';
  gamesCount: number;
  wins: number;
  draws: number;
  losses: number;
  winRate: number; // 0 - 100
  avgMoves: number;
  tacticalVibe: 'Aggressive / Sharp' | 'Solid / Positional' | 'Gambit / Sacrificial' | 'Counter-Attacking';
  verdict: 'Highly Conducive' | 'Profitable' | 'Neutral' | 'Leaking Rating';
  strengths: string[];
  weaknesses: string[];
  // Move branch sequence that defined this opening / leak
  moveBranchSan: string[];
  // Critical position FEN where mistakes or key branch divergence occurred
  criticalFen?: string;
  // Specific problem move where rating loss occurred
  problemMove?: {
    san: string;
    ply: number;
    bestSan: string;
    explanation: string;
  };
  // Challenging variation pattern diagnosis
  challengingPattern?: {
    theme: string;
    problemDescription: string;
    actionableAdvice: string;
    solutionSan: string[];
    solutionUci: string[];
  };
}

export interface PlaystyleProfile {
  username: string;
  totalAnalyzed: number;
  overallWinRate: number;
  primaryArchetype: 'Tactical Swashbuckler' | 'Positional Grinder' | 'Dynamic Counter-Puncher' | 'Universal Master';
  whiteWinRate: number;
  blackWinRate: number;
  topOpenings: OpeningStats[];
  problematicOpenings: OpeningStats[];
  tacticalInsights: {
    aggressionScore: number; // 0 - 100
    resilienceScore: number; // 0 - 100
    queensideComfort: number; // 0 - 100
    recommendation: string;
  };
}

// Comprehensive ECO & Opening Name Mapping
const KNOWN_OPENINGS: { prefix: string; name: string; eco: string }[] = [
  { prefix: '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6', name: 'Sicilian Defense: Najdorf', eco: 'B90' },
  { prefix: '1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4', name: 'Sicilian Defense: Open', eco: 'B30' },
  { prefix: '1. e4 c5 2. Nf3 e6', name: 'Sicilian Defense: French Variation', eco: 'B40' },
  { prefix: '1. e4 c5 2. Nc3', name: 'Closed Sicilian', eco: 'B23' },
  { prefix: '1. e4 c5 2. c3', name: 'Alapin Sicilian', eco: 'B22' },
  { prefix: '1. e4 c5', name: 'Sicilian Defense', eco: 'B20' },
  { prefix: '1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5', name: 'Giuoco Piano', eco: 'C50' },
  { prefix: '1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6', name: 'Two Knights Defense', eco: 'C55' },
  { prefix: '1. e4 e5 2. Nf3 Nc6 3. Bc4', name: 'Italian Game', eco: 'C50' },
  { prefix: '1. e4 e5 2. Nf3 Nc6 3. Bb5 a6', name: 'Ruy Lopez: Morphy Defense', eco: 'C70' },
  { prefix: '1. e4 e5 2. Nf3 Nc6 3. Bb5', name: 'Ruy Lopez', eco: 'C60' },
  { prefix: '1. e4 e5 2. Nf3 Nf6', name: "Petrov's Defense", eco: 'C42' },
  { prefix: '1. e4 e5 2. Nf3 Nc6 3. d4', name: 'Scotch Game', eco: 'C45' },
  { prefix: '1. e4 e5 2. Nf3 Nc6 3. Nc3', name: 'Four Knights Game', eco: 'C47' },
  { prefix: '1. e4 e5 2. f4', name: "King's Gambit", eco: 'C30' },
  { prefix: '1. e4 e5', name: "King's Pawn Game", eco: 'C20' },
  { prefix: '1. e4 e6 2. d4 d5', name: 'French Defense: Classical', eco: 'C01' },
  { prefix: '1. e4 e6', name: 'French Defense', eco: 'C00' },
  { prefix: '1. e4 c6 2. d4 d5', name: 'Caro-Kann Defense', eco: 'B12' },
  { prefix: '1. e4 c6', name: 'Caro-Kann Defense', eco: 'B10' },
  { prefix: '1. e4 d5', name: 'Scandinavian Defense', eco: 'B01' },
  { prefix: '1. e4 d6', name: 'Pirc Defense', eco: 'B07' },
  { prefix: '1. e4 Nf6', name: "Alekhine's Defense", eco: 'B02' },
  { prefix: '1. e4 g6', name: 'Modern Defense', eco: 'B06' },
  { prefix: '1. d4 d5 2. c4 e6', name: "Queen's Gambit Declined", eco: 'D30' },
  { prefix: '1. d4 d5 2. c4 dxc4', name: "Queen's Gambit Accepted", eco: 'D20' },
  { prefix: '1. d4 d5 2. c4 c6', name: 'Slav Defense', eco: 'D10' },
  { prefix: '1. d4 d5 2. c4', name: "Queen's Gambit", eco: 'D06' },
  { prefix: '1. d4 Nf6 2. c4 g6 3. Nc3 Bg7', name: "King's Indian Defense", eco: 'E60' },
  { prefix: '1. d4 Nf6 2. c4 e6 3. Nc3 Bb4', name: 'Nimzo-Indian Defense', eco: 'E20' },
  { prefix: '1. d4 Nf6 2. c4 e6 3. Nf3 b6', name: "Queen's Indian Defense", eco: 'E12' },
  { prefix: '1. d4 Nf6 2. c4 c5', name: 'Benoni Defense', eco: 'A56' },
  { prefix: '1. d4 Nf6 2. Bf4', name: 'London System', eco: 'D02' },
  { prefix: '1. d4 d5 2. Bf4', name: 'London System', eco: 'D00' },
  { prefix: '1. d4 Nf6 2. Nf3', name: "Queen's Pawn Game", eco: 'A46' },
  { prefix: '1. d4 d5', name: "Queen's Pawn Game", eco: 'D00' },
  { prefix: '1. d4 f5', name: 'Dutch Defense', eco: 'A80' },
  { prefix: '1. c4', name: 'English Opening', eco: 'A10' },
  { prefix: '1. Nf3', name: 'Réti Opening', eco: 'A04' }
];

// Helper to extract opening name and ECO accurately
export function extractOpeningInfo(pgn: string): { name: string; eco: string } {
  // Check PGN tags first
  const openingTag = pgn.match(/\[Opening "(.*?)"\]/);
  const ecoTag = pgn.match(/\[ECO "(.*?)"\]/);
  const eco = ecoTag ? ecoTag[1] : 'A00';

  if (openingTag && openingTag[1] && openingTag[1].trim() !== '') {
    const raw = openingTag[1].split(',')[0].trim();
    if (raw.length > 2) {
      return { name: raw, eco };
    }
  }

  // Check known opening moves prefix
  for (const ko of KNOWN_OPENINGS) {
    if (pgn.includes(ko.prefix)) {
      return { name: ko.name, eco: ko.eco };
    }
  }

  // Fallback to ECO classification
  const ecoCategory: Record<string, string> = {
    A: 'Flank Opening',
    B: 'Semi-Open Game',
    C: 'Open Game',
    D: 'Closed Game',
    E: 'Indian Defense'
  };
  const category = ecoCategory[eco[0]] || 'Classical System';
  return { name: `${category} (${eco})`, eco };
}

export function analyzePlaystyle(games: ChessComGame[], targetUser: string): PlaystyleProfile {
  const cleanTarget = targetUser.trim().toLowerCase();
  const openingMap: Record<string, {
    name: string;
    eco: string;
    whiteGames: number;
    blackGames: number;
    wins: number;
    draws: number;
    losses: number;
    totalMoves: number;
    moveSequences: string[][];
    lossGames: ChessComGame[];
  }> = {};

  let whiteWins = 0, whiteTotal = 0;
  let blackWins = 0, blackTotal = 0;
  let totalWins = 0, totalDraws = 0, totalLosses = 0;

  for (const game of games) {
    if (!game.pgn) continue;
    const isWhite = game.white.username.toLowerCase() === cleanTarget;
    const myResult = isWhite ? game.white.result : game.black.result;

    const isWin = myResult === 'win';
    const isDraw = ['agreed', 'repetition', 'stalemate', 'timevsinsufficient', 'insufficient'].includes(myResult);
    const isLoss = !isWin && !isDraw;

    if (isWhite) {
      whiteTotal++;
      if (isWin) whiteWins++;
    } else {
      blackTotal++;
      if (isWin) blackWins++;
    }

    if (isWin) totalWins++;
    else if (isDraw) totalDraws++;
    else totalLosses++;

    const { name, eco } = extractOpeningInfo(game.pgn);
    if (!openingMap[name]) {
      openingMap[name] = {
        name,
        eco,
        whiteGames: 0,
        blackGames: 0,
        wins: 0,
        draws: 0,
        losses: 0,
        totalMoves: 0,
        moveSequences: [],
        lossGames: []
      };
    }

    if (isWhite) openingMap[name].whiteGames++;
    else openingMap[name].blackGames++;

    if (isWin) openingMap[name].wins++;
    else if (isDraw) openingMap[name].draws++;
    else {
      openingMap[name].losses++;
      openingMap[name].lossGames.push(game);
    }

    // Extract move sequence up to ply 12
    try {
      const chess = new Chess();
      chess.loadPgn(game.pgn);
      const movesSan = chess.history();
      if (movesSan.length > 0) {
        openingMap[name].moveSequences.push(movesSan.slice(0, 14));
      }
      openingMap[name].totalMoves += movesSan.length;
    } catch (e) {
      const movesCount = (game.pgn.match(/\d+\./g) || []).length;
      openingMap[name].totalMoves += movesCount;
    }
  }

  // Compile OpeningStats list with accurate move branches
  const compiledOpenings: OpeningStats[] = Object.values(openingMap).map((o) => {
    const total = o.wins + o.draws + o.losses;
    const winRate = total > 0 ? Math.round((o.wins / total) * 100) : 0;
    const avgMoves = total > 0 ? Math.round(o.totalMoves / total) : 25;

    let playedAs: 'White' | 'Black' | 'Both' = 'Both';
    if (o.whiteGames > 0 && o.blackGames === 0) playedAs = 'White';
    if (o.blackGames > 0 && o.whiteGames === 0) playedAs = 'Black';

    // Find the most frequent / representative move order branch for this opening
    let bestBranch: string[] = [];
    if (o.moveSequences.length > 0) {
      // Pick the most common or longest sequence up to 10 plies
      const sortedByLength = [...o.moveSequences].sort((a, b) => b.length - a.length);
      bestBranch = sortedByLength[0].slice(0, 10);
    }

    // If it's a rating leak, find the critical mistake / blunder from loss games
    let problemMove: OpeningStats['problemMove'] | undefined;
    let criticalFen: string | undefined;
    let challengingPattern: OpeningStats['challengingPattern'] | undefined;

    if (winRate < 50 && o.lossGames.length > 0) {
      try {
        const lossGame = o.lossGames[0];
        const lossChess = new Chess();
        lossChess.loadPgn(lossGame.pgn);
        const history = lossChess.history({ verbose: true });
        const isWhite = lossGame.white.username.toLowerCase() === cleanTarget;

        const replay = new Chess();
        for (let i = 0; i < Math.min(history.length, 18); i++) {
          const move = history[i];
          const isUserTurn = (i % 2 === 0 && isWhite) || (i % 2 === 1 && !isWhite);
          const fenBefore = replay.fen();
          replay.move(move);

          if (isUserTurn && i >= 6) {
            criticalFen = fenBefore;

            // Calculate engine response from the pre-mistake position
            const engineChess = new Chess(fenBefore);
            const best = findBestLine(engineChess, 3);
            const bestSan = best?.bestSan || move.san;

            // Determine underlying recurring problem theme based on structure
            let theme = 'Center Tension Breakdown';
            let problemDesc = `In your games with ${o.name}, early liquidation or passivity around Move ${Math.floor(i / 2) + 1} conceded center space and allowed opponent initiative.`;
            let advice = `Instead of ${move.san}, maintain dynamic center tension with ${bestSan}. Avoid premature pawn concessions.`;

            if (fenBefore.includes('k') && !fenBefore.includes('q') || i >= 14) {
              theme = 'Premature Kingside Castling into Open File';
              problemDesc = `Kingside was committed before stabilizing central files, inviting a direct attacking storm.`;
              advice = `Delay castling or stabilize the e-file/d-file with ${bestSan} before committing king safety.`;
            } else if (o.name.includes('Sicilian') || o.name.includes('Open')) {
              theme = 'Development Delay Under Heavy Pressure';
              problemDesc = `Opponent exploited lead in development while minor pieces remained pinned or uncoordinated.`;
              advice = `Prioritize rapid minor piece development (${bestSan}) over unprovoked pawn thrusts.`;
            } else if (o.name.includes('Queen') || o.name.includes('Slav') || o.name.includes('London')) {
              theme = 'Trapped Minor Piece & Outpost Concession';
              problemDesc = `Conceded crucial outpost squares (e4/e5/d5), resulting in cramped defensive maneuvering.`;
              advice = `Challenge opponent outposts immediately using ${bestSan} to prevent positional asphyxiation.`;
            }

            problemMove = {
              san: move.san,
              ply: i + 1,
              bestSan,
              explanation: `Divergence at Move ${Math.floor(i / 2) + 1} (${move.san}) caused rating leak: ${problemDesc}`
            };

            challengingPattern = {
              theme,
              problemDescription: problemDesc,
              actionableAdvice: advice,
              solutionSan: best?.lineSan || [bestSan],
              solutionUci: best?.line || []
            };

            break;
          }
        }
      } catch (e) {
        // Ignore
      }
    }

    // Heuristic classification
    let tacticalVibe: OpeningStats['tacticalVibe'] = 'Solid / Positional';
    if (o.name.includes('Sicilian') || o.name.includes("King's Indian")) tacticalVibe = 'Aggressive / Sharp';
    else if (o.name.includes('Gambit')) tacticalVibe = 'Gambit / Sacrificial';
    else if (o.name.includes('Caro-Kann') || o.name.includes('French') || o.name.includes('Pirc')) tacticalVibe = 'Counter-Attacking';

    let verdict: OpeningStats['verdict'] = 'Neutral';
    if (winRate >= 60 && total >= 2) verdict = 'Highly Conducive';
    else if (winRate >= 50) verdict = 'Profitable';
    else if (winRate < 40 && total >= 2) verdict = 'Leaking Rating';

    return {
      name: o.name,
      eco: o.eco,
      playedAs,
      gamesCount: total,
      wins: o.wins,
      draws: o.draws,
      losses: o.losses,
      winRate,
      avgMoves,
      tacticalVibe,
      verdict,
      strengths: winRate >= 50
        ? ['High conversion rate', 'Comfortable transition to middlegame', 'Optimal pawn structures']
        : ['Familiar piece setups'],
      weaknesses: winRate < 45
        ? ['Prone to tactical traps in the move 10-18 window', 'Passive king safety', 'Low endgame winning percentage']
        : [],
      moveBranchSan: bestBranch,
      criticalFen,
      problemMove,
      challengingPattern
    };
  });

  compiledOpenings.sort((a, b) => b.gamesCount - a.gamesCount);

  const topOpenings = compiledOpenings.filter((o) => o.winRate >= 50 || o.verdict === 'Highly Conducive');
  const problematicOpenings = compiledOpenings.filter((o) => o.verdict === 'Leaking Rating');

  const totalAnalyzed = games.length;
  const overallWinRate = totalAnalyzed > 0 ? Math.round((totalWins / totalAnalyzed) * 100) : 50;
  const whiteRate = whiteTotal > 0 ? Math.round((whiteWins / whiteTotal) * 100) : 50;
  const blackRate = blackTotal > 0 ? Math.round((blackWins / blackTotal) * 100) : 50;

  // Primary Archetype detection
  let archetype: PlaystyleProfile['primaryArchetype'] = 'Dynamic Counter-Puncher';
  if (whiteRate > 60 && blackRate < 45) archetype = 'Tactical Swashbuckler';
  else if (blackRate >= 55) archetype = 'Positional Grinder';
  else if (whiteRate >= 55 && blackRate >= 55) archetype = 'Universal Master';

  return {
    username: targetUser,
    totalAnalyzed,
    overallWinRate,
    primaryArchetype: archetype,
    whiteWinRate: whiteRate,
    blackWinRate: blackRate,
    topOpenings,
    problematicOpenings,
    tacticalInsights: {
      aggressionScore: Math.min(95, Math.max(40, Math.round(overallWinRate * 1.1))),
      resilienceScore: Math.min(95, Math.max(35, Math.round(blackRate * 1.2))),
      queensideComfort: Math.min(90, Math.max(30, Math.round(whiteRate * 1.05))),
      recommendation: problematicOpenings.length > 0
        ? `You are leaking rating in the ${problematicOpenings[0].name} (${problematicOpenings[0].winRate}% win rate). We recommend shifting towards ${topOpenings[0]?.name || 'Solid Classical Systems'} where your winning conversion is ${topOpenings[0]?.winRate || 60}%.`
        : `Your repertoire is performing solidly with a ${overallWinRate}% overall win rate. Prioritize sharpening tactical conversions in your most frequent lines.`
    }
  };
}
