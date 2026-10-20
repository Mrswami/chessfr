import React from 'react';
import { MoveAnalysis, MoveRating, formatEvalPoints, MOVE_NOTATION_MAP } from '../utils/analysisEngine';
import { Award, Zap, AlertTriangle, AlertCircle, HelpCircle, CheckCircle, Flame, Swords, ExternalLink, ChevronLeft, ChevronRight, SkipBack, SkipForward } from 'lucide-react';

export interface LoadedGameInfo {
  whiteUsername: string;
  whiteRating?: number;
  blackUsername: string;
  blackRating?: number;
  result: string;
  url?: string;
  dateStr?: string;
}

interface GameInsightsProps {
  whiteAccuracy: number;
  blackAccuracy: number;
  moves: MoveAnalysis[];
  currentMoveIndex: number;
  onSelectMove: (index: number) => void;
  evaluation: number; // in centipawns
  loadedGame?: LoadedGameInfo | null;
  onPrevMove?: () => void;
  onNextMove?: () => void;
  onFirstMove?: () => void;
  onLastMove?: () => void;
}

const RATING_CONFIG: Record<MoveRating, { label: string; color: string; icon: any }> = {
  brilliant: { label: 'Brilliant', color: '#06b6d4', icon: Flame },
  best: { label: 'Best Move', color: '#10b981', icon: CheckCircle },
  excellent: { label: 'Excellent', color: '#22c55e', icon: CheckCircle },
  good: { label: 'Good', color: '#84cc16', icon: CheckCircle },
  inaccuracy: { label: 'Inaccuracy', color: '#eab308', icon: HelpCircle },
  mistake: { label: 'Mistake', color: '#f97316', icon: AlertTriangle },
  blunder: { label: 'Blunder', color: '#ef4444', icon: AlertCircle },
  book: { label: 'Book Move', color: '#a855f7', icon: Award },
};

export const GameInsightsPanel: React.FC<GameInsightsProps> = ({
  whiteAccuracy,
  blackAccuracy,
  moves,
  currentMoveIndex,
  onSelectMove,
  evaluation,
  loadedGame,
  onPrevMove,
  onNextMove,
  onFirstMove,
  onLastMove
}) => {
  const safeMoves = Array.isArray(moves) ? moves : [];
  // Count ratings
  const counts = safeMoves.reduce((acc, m) => {
    if (m && m.rating) {
      acc[m.rating] = (acc[m.rating] || 0) + 1;
    }
    return acc;
  }, {} as Record<string, number>);

  const safeEval = typeof evaluation === 'number' && !isNaN(evaluation) ? evaluation : 0;
  const evalInPawns = (safeEval / 100).toFixed(1);
  const evalPercent = Math.min(95, Math.max(5, 50 + (safeEval / 20)));
  const safeWhiteAcc = typeof whiteAccuracy === 'number' && !isNaN(whiteAccuracy) ? whiteAccuracy : 100;
  const safeBlackAcc = typeof blackAccuracy === 'number' && !isNaN(blackAccuracy) ? blackAccuracy : 100;

  return (
    <div className="insights-panel">
      {/* Loaded Game Banner (if analyzing a specific Chess.com game) */}
      {loadedGame && (
        <div className="analyzed-game-banner">
          <div className="flex items-center justify-between gap-2 mb-1.5">
            <div className="flex items-center gap-1.5 text-xs font-bold text-cyan-400">
              <Swords size={14} />
              <span>Full Game Analysis</span>
            </div>
            {loadedGame.url && (
              <a
                href={loadedGame.url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-[11px] text-cyan-400 hover:text-cyan-300 flex items-center gap-1"
              >
                <span>Chess.com</span>
                <ExternalLink size={11} />
              </a>
            )}
          </div>
          <div className="flex items-center justify-between text-xs text-slate-200 font-semibold">
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-white inline-block border border-slate-600" />
              <span>@{loadedGame.whiteUsername}</span>
              {loadedGame.whiteRating && (
                <span className="text-slate-400 font-mono text-[11px]">({loadedGame.whiteRating})</span>
              )}
            </div>
            <span className="text-slate-500 font-normal">vs</span>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-slate-900 inline-block border border-slate-600" />
              <span>@{loadedGame.blackUsername}</span>
              {loadedGame.blackRating && (
                <span className="text-slate-400 font-mono text-[11px]">({loadedGame.blackRating})</span>
              )}
            </div>
          </div>
          <div className="mt-1 flex items-center justify-between text-[11px] text-slate-400">
            <span>Result: <strong className="text-slate-200 capitalize">{loadedGame.result}</strong></span>
            {loadedGame.dateStr && <span>{loadedGame.dateStr}</span>}
          </div>
        </div>
      )}

      {/* Accuracy Cards */}
      <div className="accuracy-header">
        <div className="accuracy-card white-acc">
          <div className="acc-label">White Accuracy</div>
          <div className="acc-score">{safeWhiteAcc}%</div>
          <div className="acc-sub">Mastery Rating</div>
        </div>
        <div className="accuracy-card black-acc">
          <div className="acc-label">Black Accuracy</div>
          <div className="acc-score">{safeBlackAcc}%</div>
          <div className="acc-sub">Mastery Rating</div>
        </div>
      </div>

      {/* Dynamic Evaluation Bar */}
      <div className="eval-bar-section">
        <div className="eval-bar-label">
          <span>Engine Evaluation (Pawns)</span>
          <span className="eval-val font-mono font-bold text-sm">
            {formatEvalPoints(safeEval)}
          </span>
        </div>
        <div className="eval-track">
          <div className="eval-fill" style={{ width: `${evalPercent}%` }} />
        </div>
      </div>

      {/* Move Quality Breakdown */}
      <div className="move-quality-grid">
        <div className="quality-pill brilliant-pill" title="Brilliant sacrifice preserving winning advantage">
          <Flame size={14} />
          <span>Brilliant ({counts.brilliant || 0})</span>
        </div>
        <div className="quality-pill best-pill" title="Engine top move">
          <CheckCircle size={14} />
          <span>Best ({counts.best || 0})</span>
        </div>
        <div className="quality-pill excellent-pill" title="Strong move within 45 cp of best">
          <CheckCircle size={14} />
          <span>Great ({counts.excellent || 0})</span>
        </div>
        <div className="quality-pill good-pill" title="Solid move within 90 cp">
          <CheckCircle size={14} />
          <span>Good ({counts.good || 0})</span>
        </div>
        <div className="quality-pill inaccuracy-pill" title="Inaccuracy (90-180 cp loss)">
          <HelpCircle size={14} />
          <span>Inaccuracy ({counts.inaccuracy || 0})</span>
        </div>
        <div className="quality-pill mistake-pill" title="Mistake (180-320 cp loss)">
          <AlertTriangle size={14} />
          <span>Mistake ({counts.mistake || 0})</span>
        </div>
        <div className="quality-pill blunder-pill" title="Blunder (320+ cp loss)">
          <AlertCircle size={14} />
          <span>Blunders ({counts.blunder || 0})</span>
        </div>
        {(counts.book || 0) > 0 && (
          <div className="quality-pill book-pill" title="Opening book moves">
            <Award size={14} />
            <span>Book ({counts.book || 0})</span>
          </div>
        )}
      </div>

      {/* Move History Strip with Navigation Controls */}
      <div className="move-list-section">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-2.5">
          <div className="section-title" style={{ marginBottom: 0 }}>Move Review</div>
          {(onPrevMove || onNextMove) && (
            <div className="review-nav-bar flex items-center justify-between sm:justify-end gap-1.5 w-full sm:w-auto">
              {onFirstMove && (
                <button
                  type="button"
                  onClick={onFirstMove}
                  disabled={currentMoveIndex < 0}
                  className="nav-step-btn p-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 disabled:opacity-35 disabled:pointer-events-none transition-all border border-slate-700 active:scale-95 flex items-center justify-center"
                  title="First Move"
                >
                  <SkipBack size={18} />
                </button>
              )}
              {onPrevMove && (
                <button
                  type="button"
                  onClick={onPrevMove}
                  disabled={currentMoveIndex < 0}
                  className="nav-step-btn nav-step-primary px-3.5 py-2 rounded-lg bg-slate-800 hover:bg-cyan-900/40 text-cyan-300 disabled:opacity-35 disabled:pointer-events-none transition-all border border-cyan-800/60 active:scale-95 flex items-center gap-1.5 font-bold text-xs"
                  title="Previous Move"
                >
                  <ChevronLeft size={20} />
                  <span className="hidden xs:inline">Prev</span>
                </button>
              )}
              <span className="nav-step-counter text-xs font-mono font-bold text-slate-300 px-2.5 py-1.5 bg-slate-900/80 rounded-md border border-slate-700/60 text-center min-w-[70px]">
                {currentMoveIndex >= 0 ? `${currentMoveIndex + 1} / ${safeMoves.length}` : `Start`}
              </span>
              {onNextMove && (
                <button
                  type="button"
                  onClick={onNextMove}
                  disabled={currentMoveIndex >= safeMoves.length - 1}
                  className="nav-step-btn nav-step-primary px-3.5 py-2 rounded-lg bg-slate-800 hover:bg-cyan-900/40 text-cyan-300 disabled:opacity-35 disabled:pointer-events-none transition-all border border-cyan-800/60 active:scale-95 flex items-center gap-1.5 font-bold text-xs"
                  title="Next Move"
                >
                  <span className="hidden xs:inline">Next</span>
                  <ChevronRight size={20} />
                </button>
              )}
              {onLastMove && (
                <button
                  type="button"
                  onClick={onLastMove}
                  disabled={currentMoveIndex >= safeMoves.length - 1}
                  className="nav-step-btn p-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 disabled:opacity-35 disabled:pointer-events-none transition-all border border-slate-700 active:scale-95 flex items-center justify-center"
                  title="Last Move"
                >
                  <SkipForward size={18} />
                </button>
              )}
            </div>
          )}
        </div>
        <div className="moves-scroll">
          {safeMoves.length === 0 ? (
            <div className="p-4 text-center text-xs text-slate-400">
              No moves recorded for this game.
            </div>
          ) : (
            safeMoves.map((m, idx) => {
              const config = RATING_CONFIG[m.rating] || RATING_CONFIG.good;
              const IconComponent = config.icon;
              const isSelected = idx === currentMoveIndex;
              const moveEvalText = formatEvalPoints(m.evalAfter ?? 0);
              const annot = MOVE_NOTATION_MAP[m.rating] || MOVE_NOTATION_MAP.good;

              return (
                <div
                  key={idx}
                  onClick={() => onSelectMove(idx)}
                  className={`move-row-item group relative ${isSelected ? 'move-active' : ''}`}
                  title={`${annot.glyph ? `${annot.glyph} ` : ''}${annot.name} • Eval: ${moveEvalText} (${annot.description})`}
                >
                  <span className="move-num">{Math.floor(idx / 2) + 1}{idx % 2 === 0 ? '.' : '...'}</span>
                  <span className="move-san flex items-center gap-1">
                    <span>{m.san}</span>
                    {annot.glyph && (
                      <span
                        className="font-mono font-bold text-xs px-1 rounded"
                        style={{
                          backgroundColor: `${annot.color}25`,
                          color: annot.color,
                          border: `1px solid ${annot.color}55`
                        }}
                      >
                        {annot.glyph}
                      </span>
                    )}
                  </span>
                  <span className="move-badge" style={{ backgroundColor: `${config.color}22`, color: config.color, borderColor: config.color }}>
                    <IconComponent size={12} />
                    <span>{config.label}</span>
                  </span>
                  <span className="move-score font-mono text-xs px-1 text-slate-300 font-semibold" title={`Engine Eval after ${m.san}: ${moveEvalText}`}>
                    {moveEvalText}
                  </span>
                  <span className="move-cpl">{m.centipawnLoss > 0 ? `-${m.centipawnLoss} cp` : '✓'}</span>

                  {/* Lichess/Chess.com hover popup description */}
                  <div className="pointer-events-none absolute left-12 bottom-full mb-1.5 hidden group-hover:flex flex-col items-start z-50">
                    <div className="px-2.5 py-1.5 bg-slate-900/95 text-slate-200 text-xs rounded-lg shadow-2xl border border-slate-700 backdrop-blur-md flex items-center gap-2 whitespace-nowrap">
                      {annot.glyph && (
                        <span className="font-mono font-black text-sm" style={{ color: annot.color }}>
                          {annot.glyph}
                        </span>
                      )}
                      <div>
                        <div className="font-bold text-white text-[11px]">{annot.name}</div>
                        <div className="text-[10px] text-slate-400">{annot.description}</div>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
};
