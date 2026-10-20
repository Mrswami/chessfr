import React, { useState } from 'react';
import { OpeningStats } from '../utils/playstyleAnalyzer';
import {
  ShieldAlert,
  TrendingDown,
  GitBranch,
  Play,
  Flame,
  AlertTriangle,
  Lightbulb,
  CheckCircle,
  HelpCircle,
  Sparkles,
  ChevronRight,
  ChevronDown,
  Layers,
  Swords
} from 'lucide-react';

interface ChallengingVariationsPanelProps {
  problematicOpenings: OpeningStats[];
  username: string;
  onInspectVariationBranch: (opening: OpeningStats) => void;
  onPracticePatternDrill: (opening: OpeningStats) => void;
  onOpenConnectModal?: () => void;
}

export const ChallengingVariationsPanel: React.FC<ChallengingVariationsPanelProps> = ({
  problematicOpenings,
  username,
  onInspectVariationBranch,
  onPracticePatternDrill,
  onOpenConnectModal
}) => {
  const [expandedCard, setExpandedCard] = useState<string | null>(null);

  if (!username) {
    return (
      <div className="empty-analysis-state">
        <ShieldAlert size={48} className="text-rose-400 mb-3" />
        <h3 className="text-lg font-bold text-white mb-1">Most Challenging Variations</h3>
        <p className="text-sm text-slate-400 max-w-md text-center mb-4">
          Connect your Chess.com account to automatically detect the variations you have significant losses in, discover recurring positional breakdown themes, and drill the patterns to turn them into strengths.
        </p>
        {onOpenConnectModal && (
          <button
            className="action-btn action-btn-primary"
            onClick={onOpenConnectModal}
          >
            <Sparkles size={16} />
            <span>Connect Chess.com Account</span>
          </button>
        )}
      </div>
    );
  }

  if (problematicOpenings.length === 0) {
    return (
      <div className="empty-analysis-state">
        <CheckCircle size={48} className="text-emerald-400 mb-3" />
        <h3 className="text-lg font-bold text-white mb-1">No Challenging Variations Detected</h3>
        <p className="text-sm text-slate-400 max-w-md text-center mb-4">
          Your win rates across all opening branches are above 50% or your losses are evenly dispersed without a single recurring rating leak!
        </p>
      </div>
    );
  }

  const toggleExpand = (cardKey: string) => {
    setExpandedCard(expandedCard === cardKey ? null : cardKey);
  };

  return (
    <div className="challenging-variations-panel">
      {/* Header Banner */}
      <div className="challenging-banner">
        <div className="flex items-center gap-2 mb-1.5">
          <ShieldAlert size={20} className="text-rose-400" />
          <h2 className="text-base font-bold text-white">Challenging Variations & Loss Patterns</h2>
        </div>
        <p className="text-xs text-slate-300 leading-relaxed">
          Positions where you have significant losses that share an underlying theme or structural problem. Master the 3-move response pattern or avoid the traps.
        </p>
      </div>

      {/* List of Variations */}
      <div className="challenging-list">
        {problematicOpenings.map((op, idx) => {
          const cardKey = `challenging-${op.eco}-${idx}`;
          const isExpanded = expandedCard === cardKey;
          const pattern = op.challengingPattern;

          return (
            <div key={cardKey} className="challenging-card">
              {/* Card Header */}
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className="eco-tag bg-rose-500/20 text-rose-300">{op.eco}</span>
                  <span className="font-bold text-sm text-white">{op.name}</span>
                </div>
                <span className="verdict-tag verdict-negative">
                  <TrendingDown size={13} />
                  {op.winRate}% Win ({op.wins}W / {op.losses}L)
                </span>
              </div>

              {/* Meta strip */}
              <div className="flex items-center gap-2 text-xs text-slate-400 mb-2">
                <span>Played as <strong>{op.playedAs}</strong></span>
                <span>•</span>
                <span>{op.gamesCount} total games</span>
                <span>•</span>
                <span className="text-rose-400 font-semibold">{op.losses} losses</span>
              </div>

              {/* Underlying Problem Theme Banner */}
              {pattern && (
                <div className="thematic-pattern-box">
                  <div className="flex items-start gap-2">
                    <AlertTriangle size={15} className="text-amber-400 shrink-0 mt-0.5" />
                    <div>
                      <div className="text-xs font-bold text-amber-300 uppercase tracking-wide">
                        Underlying Theme: {pattern.theme}
                      </div>
                      <div className="text-xs text-slate-200 mt-0.5 leading-snug">
                        {pattern.problemDescription}
                      </div>
                    </div>
                  </div>

                  <div className="mt-2 pt-2 border-t border-amber-500/20 flex items-start gap-2">
                    <Lightbulb size={15} className="text-cyan-400 shrink-0 mt-0.5" />
                    <div className="text-xs text-cyan-200">
                      <strong>How to solve or avoid:</strong> {pattern.actionableAdvice}
                    </div>
                  </div>
                </div>
              )}

              {/* Move Order Branch */}
              {op.moveBranchSan && op.moveBranchSan.length > 0 && (
                <div className="my-2 p-2 bg-slate-900/90 rounded border border-slate-700/80">
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-[10px] uppercase font-bold text-slate-400 tracking-wider flex items-center gap-1">
                      <GitBranch size={11} className="text-rose-400" />
                      Critical Move Sequence:
                    </span>
                    <button
                      onClick={() => toggleExpand(cardKey)}
                      className="text-[11px] text-cyan-400 hover:text-cyan-300 flex items-center gap-0.5"
                    >
                      <span>{isExpanded ? 'Hide' : 'Details'}</span>
                      {isExpanded ? <ChevronDown size={12} /> : <ChevronRight size={12} />}
                    </button>
                  </div>

                  <div className="font-mono text-xs text-rose-200 font-semibold flex items-center gap-1.5 flex-wrap">
                    {op.moveBranchSan.map((m, mIdx) => {
                      const isProblem = op.problemMove && op.problemMove.ply === mIdx + 1;
                      return (
                        <span
                          key={mIdx}
                          className={`px-1.5 py-0.5 rounded text-[11px] ${
                            isProblem
                              ? 'bg-rose-600 text-white font-bold ring-2 ring-rose-400 animate-pulse'
                              : 'bg-slate-800/90 text-slate-300'
                          }`}
                          title={isProblem ? `Point of failure: ${m}` : undefined}
                        >
                          {mIdx % 2 === 0 ? `${Math.floor(mIdx / 2) + 1}. ` : ''}{m}
                        </span>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Action Buttons */}
              <div className="flex items-center justify-between gap-2 mt-3 pt-2 border-t border-slate-800">
                <button
                  type="button"
                  className="drill-pattern-btn"
                  onClick={() => onPracticePatternDrill(op)}
                  title="Practice the 3-move response puzzle to fix this weakness"
                >
                  <Flame size={14} className="text-amber-400" />
                  <span>Practice 3-Move Solution Drill</span>
                </button>

                <button
                  type="button"
                  className="inspect-tree-btn"
                  onClick={() => onInspectVariationBranch(op)}
                  title="Inspect this variation branch in Opening Tree"
                >
                  <GitBranch size={13} />
                  <span>Opening Tree</span>
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
