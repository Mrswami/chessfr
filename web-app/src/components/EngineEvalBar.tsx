import React from 'react';
import { formatEvalPoints } from '../utils/analysisEngine';

interface EvalBarProps {
  evaluation: number; // Centipawns from White's perspective (+100 = White +1 pawn)
  orientation?: 'w' | 'b';
  compact?: boolean;
}

/**
 * Vertical per-move engine evaluation bar with +1 / +2 pawn point rating system.
 * White winning fills White up; Black winning fills Black up.
 * Respects board orientation (White on bottom or Black on bottom).
 */
export const EngineEvalBar: React.FC<EvalBarProps> = ({
  evaluation,
  orientation = 'w',
  compact = false
}) => {
  const safeEval = typeof evaluation === 'number' && !isNaN(evaluation) ? evaluation : 0;
  // Convert centipawns to pawn points: 100 cp = 1.0 pawn
  const pawns = safeEval / 100;
  const isMate = Math.abs(safeEval) >= 20000;

  // Modern chess app eval percentage formula with sigmoid/log scale:
  // 0 -> 50%
  // +1 pawn (+100) -> ~60%
  // +3 pawns (+300) -> ~75%
  // +5 pawns (+500) -> ~88%
  // Mate -> 100% or 0%
  let whitePercent = 50;
  if (isMate) {
    whitePercent = safeEval > 0 ? 100 : 0;
  } else {
    // Standard logistic curve: 100 / (1 + 10^(-pawns / 4))
    const raw = 100 / (1 + Math.pow(10, -pawns / 4));
    whitePercent = Math.min(96, Math.max(4, raw));
  }

  // If orientation is Black at bottom, flip bar fill perspective
  const bottomFillPercent = orientation === 'w' ? whitePercent : (100 - whitePercent);
  const bottomColorIsWhite = orientation === 'w';

  // Eval formatted string (+1.5, -2.4, M1, 0.0)
  const evalText = formatEvalPoints(safeEval, isMate);
  const isWhiteAdvantage = safeEval > 0;
  const isZero = Math.abs(safeEval) < 15;

  return (
    <div
      className={`engine-eval-bar-wrapper ${compact ? 'eval-bar-compact' : ''}`}
      title={`Engine Evaluation: ${evalText} (${evaluation > 0 ? 'White' : evaluation < 0 ? 'Black' : 'Equal'} advantage)`}
    >
      <div className="engine-eval-track">
        {/* Top bar portion (Dark side if White bottom, White side if Black bottom) */}
        <div
          className={`eval-top-half ${bottomColorIsWhite ? 'eval-side-black' : 'eval-side-white'}`}
          style={{ height: `${100 - bottomFillPercent}%` }}
        >
          {/* Label on top when that side has significant advantage */}
          {((bottomColorIsWhite && !isWhiteAdvantage && !isZero) || (!bottomColorIsWhite && isWhiteAdvantage && !isZero)) && (
            <span className="eval-badge top-badge font-mono">
              {evalText}
            </span>
          )}
        </div>

        {/* Bottom bar portion (White side if White bottom, Dark side if Black bottom) */}
        <div
          className={`eval-bottom-half ${bottomColorIsWhite ? 'eval-side-white' : 'eval-side-black'}`}
          style={{ height: `${bottomFillPercent}%` }}
        >
          {/* Label on bottom when that side has advantage */}
          {((bottomColorIsWhite && isWhiteAdvantage && !isZero) || (!bottomColorIsWhite && !isWhiteAdvantage && !isZero)) && (
            <span className="eval-badge bottom-badge font-mono">
              {evalText}
            </span>
          )}

          {/* Equal balance indicator in center when near 0.0 */}
          {isZero && (
            <span className="eval-badge center-badge font-mono">
              0.0
            </span>
          )}
        </div>
      </div>
    </div>
  );
};
