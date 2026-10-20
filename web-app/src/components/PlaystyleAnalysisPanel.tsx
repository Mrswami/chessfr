import React, { useState } from 'react';
import { PlaystyleProfile, OpeningStats } from '../utils/playstyleAnalyzer';
import {
  TrendingUp,
  TrendingDown,
  Compass,
  Swords,
  ShieldAlert,
  ShieldCheck,
  Zap,
  Target,
  Sparkles,
  Award,
  GitBranch,
  ChevronRight,
  ChevronDown,
  Play,
  Flame,
  AlertCircle
} from 'lucide-react';
import { ChessComGame } from '../services/chessComService';
import { RecentGamesList } from './RecentGamesList';

interface PlaystyleAnalysisProps {
  profile: PlaystyleProfile | null;
  onSelectOpening: (openingName: string) => void;
  onInspectOpeningBranch?: (opening: OpeningStats) => void;
  onOpenConnectModal: () => void;
  chessComUsername: string;
  recentGames?: ChessComGame[];
  onAnalyzeGame?: (game: ChessComGame) => void;
  activeGameUrl?: string | null;
}

export const PlaystyleAnalysisPanel: React.FC<PlaystyleAnalysisProps> = ({
  profile,
  onSelectOpening,
  onInspectOpeningBranch,
  onOpenConnectModal,
  chessComUsername,
  recentGames = [],
  onAnalyzeGame,
  activeGameUrl
}) => {
  const [expandedOpening, setExpandedOpening] = useState<string | null>(null);

  if (!chessComUsername || !profile || profile.totalAnalyzed === 0) {
    return (
      <div className="empty-analysis-state">
        <Compass size={48} className="text-cyan-400 mb-3" />
        <h3 className="text-lg font-bold text-white mb-1">Playstyle & Opening Diagnostics</h3>
        <p className="text-sm text-slate-400 max-w-md text-center mb-4">
          Connect your Chess.com username to dissect your games. Discover which openings and tactical ideas yield high win rates for your unique playstyle, and which ones are leaking rating.
        </p>
        <button
          className="action-btn action-btn-primary"
          onClick={onOpenConnectModal}
        >
          <Sparkles size={16} />
          <span>Connect Chess.com Account</span>
        </button>
      </div>
    );
  }

  const {
    primaryArchetype,
    overallWinRate,
    whiteWinRate,
    blackWinRate,
    topOpenings,
    problematicOpenings,
    tacticalInsights
  } = profile;

  const toggleExpand = (e: React.MouseEvent, key: string) => {
    e.stopPropagation();
    setExpandedOpening(expandedOpening === key ? null : key);
  };

  const handleCardClick = (op: OpeningStats) => {
    if (onInspectOpeningBranch) {
      onInspectOpeningBranch(op);
    } else {
      onSelectOpening(op.name);
    }
  };

  return (
    <div className="playstyle-panel">
      {/* Playstyle Archetype Card */}
      <div className="archetype-banner">
        <div className="archetype-badge">
          <Award size={20} className="text-amber-400" />
          <span>Player Archetype</span>
        </div>
        <h2 className="archetype-title">{primaryArchetype}</h2>
        <p className="archetype-desc">
          Based on {profile.totalAnalyzed} games analyzed for @{profile.username}. Your style thrives when initiating sharp tactical threats and active piece piece coordination.
        </p>

        {/* Win Rate Stats Trio */}
        <div className="stats-trio">
          <div className="stat-box">
            <span className="stat-label">Overall Win Rate</span>
            <span className="stat-value">{overallWinRate}%</span>
          </div>
          <div className="stat-box">
            <span className="stat-label">White (1st Move)</span>
            <span className="stat-value text-emerald-400">{whiteWinRate}%</span>
          </div>
          <div className="stat-box">
            <span className="stat-label">Black (Defense)</span>
            <span className="stat-value text-cyan-400">{blackWinRate}%</span>
          </div>
        </div>
      </div>

      {/* Strategic Recommendation */}
      <div className="recommendation-callout">
        <Zap size={20} className="text-amber-400 flex-shrink-0" />
        <div>
          <div className="font-bold text-white text-sm mb-1">Coaching Recommendation</div>
          <div className="text-xs text-slate-300 leading-relaxed">
            {tacticalInsights.recommendation}
          </div>
        </div>
      </div>

      {/* Last 5 Games with Opponent & Result */}
      {recentGames.length > 0 && onAnalyzeGame && (
        <RecentGamesList
          games={recentGames}
          username={chessComUsername}
          onAnalyzeGame={onAnalyzeGame}
          activeGameUrl={activeGameUrl}
        />
      )}

      {/* Opening Conduciveness Section */}
      <div className="conduciveness-section">
        {/* Highly Conducive Openings */}
        <div className="category-block">
          <div className="category-header text-emerald-400 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <ShieldCheck size={18} />
              <span>Most Conducive to Your Style (Keep Playing)</span>
            </div>
            <span className="text-[11px] text-slate-400 font-normal">Click card to inspect branch</span>
          </div>

          <div className="openings-grid">
            {topOpenings.length > 0 ? (
              topOpenings.map((op, idx) => {
                const cardKey = `top-${op.name}-${idx}`;
                const isExpanded = expandedOpening === cardKey;

                return (
                  <div
                    key={cardKey}
                    className="opening-metric-card border-emerald-500/30 hover:border-emerald-400/60"
                    onClick={() => handleCardClick(op)}
                  >
                    <div className="metric-header">
                      <div className="flex items-center gap-2">
                        <span className="eco-tag">{op.eco}</span>
                        <span className="opening-metric-name">{op.name}</span>
                      </div>
                      <span className="verdict-tag verdict-positive">
                        <TrendingUp size={14} />
                        {op.winRate}% Win
                      </span>
                    </div>

                    <div className="metric-meta">
                      <span>{op.gamesCount} games</span>
                      <span>•</span>
                      <span>{op.tacticalVibe}</span>
                      <span>•</span>
                      <span>As {op.playedAs}</span>
                    </div>

                    {/* Move Order Branch Summary */}
                    {op.moveBranchSan && op.moveBranchSan.length > 0 && (
                      <div className="my-2 p-2 bg-slate-900/90 rounded border border-slate-700/80">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-[10px] uppercase font-bold text-slate-400 tracking-wider flex items-center gap-1">
                            <GitBranch size={11} className="text-emerald-400" />
                            Key Move Order Branch:
                          </span>
                          <button
                            onClick={(e) => toggleExpand(e, cardKey)}
                            className="text-[11px] text-cyan-400 hover:text-cyan-300 flex items-center gap-0.5"
                          >
                            <span>{isExpanded ? 'Hide' : 'Details'}</span>
                            {isExpanded ? <ChevronDown size={12} /> : <ChevronRight size={12} />}
                          </button>
                        </div>
                        <div className="font-mono text-xs text-emerald-300 font-semibold flex items-center gap-1.5 flex-wrap">
                          {op.moveBranchSan.map((m, mIdx) => (
                            <span key={mIdx} className="bg-slate-800/90 px-1.5 py-0.5 rounded text-[11px]">
                              {mIdx % 2 === 0 ? `${Math.floor(mIdx / 2) + 1}. ` : ''}{m}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}

                    <div className="strengths-list">
                      {op.strengths.map((s, i) => (
                        <span key={i} className="strength-item">✓ {s}</span>
                      ))}
                    </div>

                    {/* Action Bar */}
                    <div className="mt-2 pt-2 border-t border-slate-800 flex items-center justify-between text-xs text-slate-400">
                      <span className="text-[11px] text-cyan-400/90 flex items-center gap-1">
                        <GitBranch size={12} />
                        <span>Inspect in Opening Tree</span>
                      </span>
                      <ChevronRight size={14} className="text-slate-500" />
                    </div>
                  </div>
                );
              })
            ) : (
              <div className="text-xs text-slate-500 italic p-3">
                No dominant opening patterns yet with &gt;50% score.
              </div>
            )}
          </div>
        </div>

        {/* Problematic / Leaking Openings */}
        <div className="category-block" style={{ marginTop: '1.25rem' }}>
          <div className="category-header text-rose-400 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <ShieldAlert size={18} />
              <span>Rating Leak Anomalies (Re-evaluate or Drop)</span>
            </div>
            <span className="text-[11px] text-slate-400 font-normal">Click card to inspect problem branch</span>
          </div>

          <div className="openings-grid">
            {problematicOpenings.length > 0 ? (
              problematicOpenings.map((op, idx) => {
                const cardKey = `leak-${op.name}-${idx}`;
                const isExpanded = expandedOpening === cardKey;

                return (
                  <div
                    key={cardKey}
                    className="opening-metric-card border-rose-500/30 hover:border-rose-400/70"
                    onClick={() => handleCardClick(op)}
                  >
                    <div className="metric-header">
                      <div className="flex items-center gap-2">
                        <span className="eco-tag bg-rose-500/20 text-rose-300">{op.eco}</span>
                        <span className="opening-metric-name">{op.name}</span>
                      </div>
                      <span className="verdict-tag verdict-negative">
                        <TrendingDown size={14} />
                        {op.winRate}% Win
                      </span>
                    </div>

                    <div className="metric-meta">
                      <span>{op.gamesCount} games</span>
                      <span>•</span>
                      <span>{op.wins}W / {op.losses}L</span>
                      <span>•</span>
                      <span>As {op.playedAs}</span>
                    </div>

                    {/* Move Order Branch with Leak Callout */}
                    {op.moveBranchSan && op.moveBranchSan.length > 0 && (
                      <div className="my-2 p-2 bg-rose-950/25 rounded border border-rose-900/60">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-[10px] uppercase font-bold text-rose-300 tracking-wider flex items-center gap-1">
                            <Flame size={11} className="text-rose-400" />
                            Problematic Move Order Branch:
                          </span>
                          <button
                            onClick={(e) => toggleExpand(e, cardKey)}
                            className="text-[11px] text-rose-400 hover:text-rose-300 flex items-center gap-0.5"
                          >
                            <span>{isExpanded ? 'Hide' : 'Details'}</span>
                            {isExpanded ? <ChevronDown size={12} /> : <ChevronRight size={12} />}
                          </button>
                        </div>

                        {/* Move Branch Sequence */}
                        <div className="font-mono text-xs text-rose-200 font-semibold flex items-center gap-1.5 flex-wrap">
                          {op.moveBranchSan.map((m, mIdx) => {
                            const isDivergence = op.problemMove && op.problemMove.ply === mIdx + 1;
                            return (
                              <span
                                key={mIdx}
                                className={`px-1.5 py-0.5 rounded text-[11px] ${
                                  isDivergence
                                    ? 'bg-rose-600 text-white font-bold ring-2 ring-rose-400 animate-pulse'
                                    : 'bg-slate-900/80 text-slate-300'
                                }`}
                                title={isDivergence ? `Root of rating leak: ${m}` : undefined}
                              >
                                {mIdx % 2 === 0 ? `${Math.floor(mIdx / 2) + 1}. ` : ''}{m}
                              </span>
                            );
                          })}
                        </div>

                        {/* Problem Move Diagnostic Callout */}
                        {op.problemMove && (
                          <div className="mt-2 text-xs text-rose-300/95 bg-rose-950/60 p-2 rounded border border-rose-800/80 flex items-start gap-1.5">
                            <AlertCircle size={14} className="text-rose-400 shrink-0 mt-0.5" />
                            <span>
                              <strong>Root Issue:</strong> {op.problemMove.explanation}
                            </span>
                          </div>
                        )}
                      </div>
                    )}

                    <div className="weaknesses-list">
                      {op.weaknesses.map((w, i) => (
                        <span key={i} className="weakness-item">⚠️ {w}</span>
                      ))}
                    </div>

                    {/* Action Bar */}
                    <div className="mt-2 pt-2 border-t border-slate-800 flex items-center justify-between text-xs text-slate-400">
                      <span className="text-[11px] text-rose-400 font-semibold flex items-center gap-1">
                        <Play size={12} />
                        <span>Inspect & Fix in Opening Tree →</span>
                      </span>
                      <ChevronRight size={14} className="text-rose-400" />
                    </div>
                  </div>
                );
              })
            ) : (
              <div className="clean-slate-alert">
                <ShieldCheck size={18} className="text-emerald-400" />
                <span>No major rating leak openings detected! Your loss distribution is evenly scattered.</span>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
