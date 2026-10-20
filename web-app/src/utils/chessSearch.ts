import { Chess, Square, Move } from 'chess.js';

// Piece square values (centipawns)
const PIECE_VALUES: Record<string, number> = {
  p: 100,
  n: 320,
  b: 330,
  r: 500,
  q: 900,
  k: 20000
};

// Positional bonuses for center control and development
const PAWN_TABLE = [
  0,  0,  0,  0,  0,  0,  0,  0,
  50, 50, 50, 50, 50, 50, 50, 50,
  10, 10, 20, 30, 30, 20, 10, 10,
  5,  5, 10, 25, 25, 10,  5,  5,
  0,  0,  0, 20, 20,  0,  0,  0,
  5, -5,-10,  0,  0,-10, -5,  5,
  5, 10, 10,-20,-20, 10, 10,  5,
  0,  0,  0,  0,  0,  0,  0,  0
];

const KNIGHT_TABLE = [
  -50,-40,-30,-30,-30,-30,-40,-50,
  -40,-20,  0,  0,  0,  0,-20,-40,
  -30,  0, 10, 15, 15, 10,  0,-30,
  -30,  5, 15, 20, 20, 15,  5,-30,
  -30,  0, 15, 20, 20, 15,  0,-30,
  -30,  5, 10, 15, 15, 10,  5,-30,
  -40,-20,  0,  5,  5,  0,-20,-40,
  -50,-40,-30,-30,-30,-30,-40,-50
];

const BISHOP_TABLE = [
  -20,-10,-10,-10,-10,-10,-10,-20,
  -10,  0,  0,  0,  0,  0,  0,-10,
  -10,  0,  5, 10, 10,  5,  0,-10,
  -10,  5,  5, 10, 10,  5,  5,-10,
  -10,  0, 10, 10, 10, 10,  0,-10,
  -10, 10, 10, 10, 10, 10, 10,-10,
  -10,  5,  0,  0,  0,  0,  5,-10,
  -20,-10,-10,-10,-10,-10,-10,-20
];

export function evaluatePosition(chess: Chess): number {
  if (chess.isCheckmate()) {
    return chess.turn() === 'w' ? -30000 : 30000;
  }
  if (chess.isDraw() || chess.isStalemate() || chess.isThreefoldRepetition()) {
    return 0;
  }

  const board = chess.board();
  let score = 0;

  for (let r = 0; r < 8; r++) {
    for (let c = 0; c < 8; c++) {
      const piece = board[r][c];
      if (!piece) continue;

      const val = PIECE_VALUES[piece.type] || 0;
      let posBonus = 0;
      const idx = r * 8 + c;
      const flippedIdx = (7 - r) * 8 + c;

      if (piece.type === 'p') {
        posBonus = piece.color === 'w' ? PAWN_TABLE[idx] : PAWN_TABLE[flippedIdx];
      } else if (piece.type === 'n') {
        posBonus = piece.color === 'w' ? KNIGHT_TABLE[idx] : KNIGHT_TABLE[flippedIdx];
      } else if (piece.type === 'b') {
        posBonus = piece.color === 'w' ? BISHOP_TABLE[idx] : BISHOP_TABLE[flippedIdx];
      }

      const total = val + posBonus;
      score += piece.color === 'w' ? total : -total;
    }
  }

  return score;
}

export interface BestLineResult {
  bestMove: string; // UCI format e.g. "e2e4"
  bestSan: string;
  line: string[];   // Sequence of UCI moves e.g. ["e2e4", "e7e5", "g1f3"]
  lineSan: string[];
  eval: number;
}

/**
 * Recursive search returning the evaluation and principal variation line
 */
function searchPV(
  chess: Chess,
  depth: number,
  alpha: number,
  beta: number,
  isMaximizing: boolean
): { eval: number; lineUCI: string[]; lineSan: string[] } {
  if (depth === 0 || chess.isGameOver()) {
    return { eval: evaluatePosition(chess), lineUCI: [], lineSan: [] };
  }

  const moves = chess.moves({ verbose: true });
  if (moves.length === 0) {
    return { eval: evaluatePosition(chess), lineUCI: [], lineSan: [] };
  }

  // Quick heuristic sorting: captures and checks first
  moves.sort((a, b) => {
    const scoreA = (a.captured ? 100 : 0) + (a.san.includes('+') ? 50 : 0);
    const scoreB = (b.captured ? 100 : 0) + (b.san.includes('+') ? 50 : 0);
    return scoreB - scoreA;
  });

  if (isMaximizing) {
    let maxEval = -Infinity;
    let bestLineUCI: string[] = [];
    let bestLineSan: string[] = [];

    for (const move of moves) {
      chess.move(move);
      const res = searchPV(chess, depth - 1, alpha, beta, false);
      chess.undo();

      if (res.eval > maxEval) {
        maxEval = res.eval;
        bestLineUCI = [`${move.from}${move.to}`, ...res.lineUCI];
        bestLineSan = [move.san, ...res.lineSan];
      }
      alpha = Math.max(alpha, res.eval);
      if (beta <= alpha) break;
    }
    return { eval: maxEval, lineUCI: bestLineUCI, lineSan: bestLineSan };
  } else {
    let minEval = Infinity;
    let bestLineUCI: string[] = [];
    let bestLineSan: string[] = [];

    for (const move of moves) {
      chess.move(move);
      const res = searchPV(chess, depth - 1, alpha, beta, true);
      chess.undo();

      if (res.eval < minEval) {
        minEval = res.eval;
        bestLineUCI = [`${move.from}${move.to}`, ...res.lineUCI];
        bestLineSan = [move.san, ...res.lineSan];
      }
      beta = Math.min(beta, res.eval);
      if (beta <= alpha) break;
    }
    return { eval: minEval, lineUCI: bestLineUCI, lineSan: bestLineSan };
  }
}

/**
 * Searches for the best line (up to depth plies) using Minimax with Alpha-Beta pruning
 */
export function findBestLine(chess: Chess, maxPlies: number = 3): BestLineResult | null {
  const isMaximizing = chess.turn() === 'w';
  const res = searchPV(chess, maxPlies, -Infinity, Infinity, isMaximizing);

  if (res.lineUCI.length === 0) return null;

  return {
    bestMove: res.lineUCI[0],
    bestSan: res.lineSan[0],
    line: res.lineUCI.slice(0, maxPlies),
    lineSan: res.lineSan.slice(0, maxPlies),
    eval: res.eval
  };
}

