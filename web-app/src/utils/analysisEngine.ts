import { Chess, Square, Move } from 'chess.js';
import { evaluatePosition, findBestLine } from './chessSearch';

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
  if (isSacrifice && cpLoss <= 25 && isWinningAfter) {
    return 'brilliant';
  }

  if (cpLoss <= 15) return 'best';
  if (cpLoss <= 45) return 'excellent';
  if (cpLoss <= 90) return 'good';
  if (cpLoss <= 180) return 'inaccuracy';
  if (cpLoss <= 320) return 'mistake';
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

// Full positional engine evaluation (pawn = 100cp, minors = 320-330cp, rooks = 500cp, queen = 900cp + center/piece-square tables)
export function getEngineEval(chess: Chess): number {
  return evaluatePosition(chess);
}

// Backward compatible export for existing callers
export function getMaterialEval(chess: Chess): number {
  return evaluatePosition(chess);
}

/**
 * Formats centipawn evaluation into human-readable +1 / -2 pawn point rating or mate
 */
export function formatEvalPoints(evalCp: number, isMate?: boolean, mateInMoves?: number): string {
  if (Math.abs(evalCp) >= 20000) {
    const moves = mateInMoves ? Math.abs(mateInMoves) : 1;
    return evalCp > 0 ? `M${moves}` : `-M${moves}`;
  }
  const pawns = evalCp / 100;
  if (pawns === 0) return '0.0';
  return pawns > 0 ? `+${pawns.toFixed(1)}` : pawns.toFixed(1);
}
