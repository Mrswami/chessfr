import { Chess, Square, Move } from 'chess.js';

export type MoveRating = 'brilliant' | 'best' | 'excellent' | 'good' | 'inaccuracy' | 'mistake' | 'blunder' | 'book';

export interface MoveAnalysis {
  san: string;
  from: string;
  to: string;
  color: 'w' | 'b';
  evalBefore: number;
  evalAfter: number;
  centipawnLoss: number;
  rating: MoveRating;
  bestMoveSan?: string;
}

export interface GameSummary {
  whiteAccuracy: number;
  blackAccuracy: number;
  whiteBrilliant: number;
  blackBrilliant: number;
  whiteBlunders: number;
  blackBlunders: number;
  moveHistory: MoveAnalysis[];
}

export function classifyMove(
  evalBefore: number,
  evalAfter: number,
  turn: 'w' | 'b',
  isSacrifice: boolean,
  isWinningAfter: boolean
): MoveRating {
  // Centipawn delta from the perspective of the player making the move
  const cpLoss = turn === 'w' ? (evalBefore - evalAfter) : (evalAfter - evalBefore);

  // Brilliant move: A sacrifice that maintains or increases a strong winning advantage
  if (isSacrifice && cpLoss <= 15 && isWinningAfter) {
    return 'brilliant';
  }

  if (cpLoss <= 10) return 'best';
  if (cpLoss <= 35) return 'excellent';
  if (cpLoss <= 70) return 'good';
  if (cpLoss <= 150) return 'inaccuracy';
  if (cpLoss <= 300) return 'mistake';
  return 'blunder';
}

export function calculateAccuracy(moves: MoveAnalysis[], color: 'w' | 'b'): number {
  const playerMoves = moves.filter(m => m.color === color);
  if (playerMoves.length === 0) return 100;

  // Chess.com style accuracy formula: 103.166 * exp(-0.0435 * cpl) - 3.166
  const totalCpl = playerMoves.reduce((acc, m) => acc + Math.max(0, m.centipawnLoss), 0);
  const avgCpl = totalCpl / playerMoves.length;

  const rawScore = 103.166 * Math.exp(-0.0435 * (avgCpl / 10)) - 3.166;
  return Math.min(100, Math.max(30, Math.round(rawScore * 10) / 10));
}

// Evaluate piece material values for heuristics
export function getMaterialEval(chess: Chess): number {
  const board = chess.board();
  const values: Record<string, number> = { p: 100, n: 320, b: 330, r: 500, q: 900, k: 0 };
  let score = 0;

  for (const row of board) {
    for (const piece of row) {
      if (!piece) continue;
      const val = values[piece.type] || 0;
      score += piece.color === 'w' ? val : -val;
    }
  }
  return score;
}
