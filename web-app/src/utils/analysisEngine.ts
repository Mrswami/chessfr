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
  isWinningAfter: boolean,
  bestEngineEval?: number, // Optional evaluation of the top engine move from the position
  isOnlyGoodMove?: boolean  // Sole saving or winning move found
): MoveRating {
  // If bestEngineEval is provided, compare player move against best engine line
  // Otherwise, use evaluation change delta
  let cpLoss: number;
  if (typeof bestEngineEval === 'number' && !isNaN(bestEngineEval)) {
    cpLoss = turn === 'w' ? (bestEngineEval - evalAfter) : (evalAfter - bestEngineEval);
  } else {
    cpLoss = turn === 'w' ? (evalBefore - evalAfter) : (evalAfter - evalBefore);
  }

  // Ensure cpLoss is not distorted by slight engine horizon fluctuations
  const normalizedLoss = Math.max(0, cpLoss);
  const evalForPlayer = turn === 'w' ? evalAfter : -evalAfter;

  // 1. Brilliant move (!!): Truly rare piece sacrifice preserving winning advantage
  if (isSacrifice && isWinningAfter && normalizedLoss <= 15 && evalForPlayer >= 150) {
    return 'brilliant';
  }

  // 2. Great Move (!?): Truly exceptional sole-saving/winning move in difficult or decisive positions
  // Must be verified as the single continuation when all alternatives dropped significant advantage
  if (isOnlyGoodMove && normalizedLoss <= 15 && evalForPlayer >= -50) {
    return 'excellent';
  }

  // 3. Calibrated standard move tiers reflecting true engine quality:
  if (normalizedLoss <= 15) return 'best';        // Top engine choice
  if (normalizedLoss <= 60) return 'good';        // Sound natural move
  if (normalizedLoss <= 140) return 'inaccuracy'; // Minor inaccuracy (?!)
  if (normalizedLoss <= 275) return 'mistake';    // Clear mistake / missed tactic (?)
  return 'blunder';                               // Blunder / decisive loss (??)
}


export function calculateAccuracy(moves: MoveAnalysis[], color: 'w' | 'b'): number {
  if (!Array.isArray(moves)) return 100;
  const playerMoves = moves.filter(m => m && m.color === color);
  if (playerMoves.length === 0) return 100;

  // Chess.com style accuracy formula: 103.166 * exp(-0.0435 * cpl) - 3.166
  const totalCpl = playerMoves.reduce((acc, m) => {
    const loss = typeof m.centipawnLoss === 'number' && !isNaN(m.centipawnLoss) ? m.centipawnLoss : 0;
    return acc + Math.max(0, loss);
  }, 0);
  const avgCpl = totalCpl / playerMoves.length;

  const rawScore = 103.166 * Math.exp(-0.0435 * (avgCpl / 10)) - 3.166;
  if (isNaN(rawScore)) return 100;
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
  const safeVal = typeof evalCp === 'number' && !isNaN(evalCp) ? evalCp : 0;
  if (Math.abs(safeVal) >= 20000) {
    const moves = mateInMoves ? Math.abs(mateInMoves) : 1;
    return safeVal > 0 ? `M${moves}` : `-M${moves}`;
  }
  const pawns = safeVal / 100;
  if (pawns === 0) return '0.0';
  return pawns > 0 ? `+${pawns.toFixed(1)}` : pawns.toFixed(1);
}

/**
 * Short-hand chess annotation glyphs used by Lichess and Chess.com
 * !! = Brilliant
 * !  = Best
 * !? = Great / Interesting / Excellent
 * (none or ✓) = Good
 * ?! = Inaccuracy
 * ?  = Mistake
 * ?? = Blunder
 * 📖 = Book
 */
export const MOVE_NOTATION_MAP: Record<MoveRating, {
  glyph: string;
  name: string;
  symbol: string;
  description: string;
  color: string;
  bgColor: string;
}> = {
  brilliant: {
    glyph: '!!',
    name: 'Brilliant',
    symbol: '!!',
    description: 'A brilliant sacrifice that maintains or increases a strong winning advantage (!!)',
    color: '#06b6d4',
    bgColor: 'rgba(6, 182, 212, 0.2)'
  },
  best: {
    glyph: '',
    name: 'Best Move',
    symbol: '!',
    description: 'The engine\'s top-choice move (!)',
    color: '#10b981',
    bgColor: 'rgba(16, 185, 129, 0.2)'
  },
  excellent: {
    glyph: '!?',
    name: 'Great Move',
    symbol: '!?',
    description: 'An excellent, strong continuation (!?)',
    color: '#22c55e',
    bgColor: 'rgba(34, 197, 94, 0.2)'
  },
  good: {
    glyph: '',
    name: 'Good Move',
    symbol: '',
    description: 'A solid, reliable move',
    color: '#84cc16',
    bgColor: 'rgba(132, 204, 22, 0.15)'
  },
  inaccuracy: {
    glyph: '?!',
    name: 'Inaccuracy',
    symbol: '?!',
    description: 'An inaccuracy that slightly gives away advantage (?!)',
    color: '#eab308',
    bgColor: 'rgba(234, 179, 8, 0.2)'
  },
  mistake: {
    glyph: '?',
    name: 'Mistake',
    symbol: '?',
    description: 'A mistake that noticeably hurts the position (?)',
    color: '#f97316',
    bgColor: 'rgba(249, 115, 22, 0.2)'
  },
  blunder: {
    glyph: '??',
    name: 'Blunder',
    symbol: '??',
    description: 'A critical blunder that swings evaluation (??)',
    color: '#ef4444',
    bgColor: 'rgba(239, 68, 68, 0.25)'
  },
  book: {
    glyph: '📖',
    name: 'Book Move',
    symbol: '📖',
    description: 'Standard opening book move',
    color: '#a855f7',
    bgColor: 'rgba(168, 85, 247, 0.2)'
  }
};

/**
 * Returns the short-hand notation and details for a move rating
 */
export function getMoveAnnotation(rating: MoveRating) {
  return MOVE_NOTATION_MAP[rating] || MOVE_NOTATION_MAP.good;
}
