import React, { useState } from 'react';
import { TacticalPuzzle, OpeningLine } from '../data/chessContent';
import { UserPuzzleProgress, MasteryStatus, SavedPosition } from '../services/masteryStorageService';
import { Target, BookOpen, ChevronRight, Award, Sparkles, CheckCircle, Clock, AlertTriangle, Flame, ShieldAlert, Archive, Trash2, Play, Bookmark } from 'lucide-react';

interface TrainingModuleProps {
  puzzles: TacticalPuzzle[];
  currentPuzzleId: string;
  onSelectPuzzle: (puzzle: TacticalPuzzle) => void;
  openings: OpeningLine[];
  onSelectOpening: (line: OpeningLine) => void;
  activeTab: 'puzzles' | 'openings' | 'archive';
  onTabChange: (tab: 'puzzles' | 'openings' | 'archive') => void;
  progressMap?: Record<string, UserPuzzleProgress>;
  savedPositions?: SavedPosition[];
  onSelectSavedPosition?: (pos: SavedPosition) => void;
  onDeleteSavedPosition?: (posId: string) => void;
}

export const TrainingModulesPanel: React.FC<TrainingModuleProps> = ({
  puzzles,
  currentPuzzleId,
  onSelectPuzzle,
  openings,
  onSelectOpening,
  activeTab,
  onTabChange,
  progressMap = {},
  savedPositions = [],
  onSelectSavedPosition,
  onDeleteSavedPosition
}) => {
  const [filter, setFilter] = useState<'all' | 'needs_work' | 'reviewing' | 'mastered' | 'three_move' | 'challenging'>('all');

  const filteredPuzzles = puzzles.filter((p) => {
    const prog = progressMap[p.id];
    const status: MasteryStatus = prog?.status || 'needs_work';
    if (filter === 'needs_work') return status === 'needs_work';
    if (filter === 'reviewing') return status === 'reviewing';
    if (filter === 'mastered') return status === 'mastered';
    if (filter === 'three_move') return Boolean(p.isThreeMovePlan);
    if (filter === 'challenging') {
      return p.id.startsWith('challenging-var') || (p.theme && p.theme.includes('Challenging'));
    }
    return true;
  });

  return (
    <div className="training-panel">
      {/* Navigation Tabs */}
      <div className="training-tabs">
        <button
          className={`tab-btn ${activeTab === 'puzzles' ? 'tab-active' : ''}`}
          onClick={() => onTabChange('puzzles')}
        >
          <Target size={16} />
          <span>Tactics & Drills</span>
        </button>
        <button
          className={`tab-btn ${activeTab === 'archive' ? 'tab-active' : ''}`}
          onClick={() => onTabChange('archive')}
        >
          <Archive size={16} />
          <span>Positional Archive ({savedPositions.length})</span>
        </button>
        <button
          className={`tab-btn ${activeTab === 'openings' ? 'tab-active' : ''}`}
          onClick={() => onTabChange('openings')}
        >
          <BookOpen size={16} />
          <span>Openings & Theory</span>
        </button>
      </div>

      {activeTab === 'puzzles' ? (
        <div className="puzzle-list">
          <div className="module-banner">
            <Sparkles size={18} className="text-amber-400" />
            <div>
              <div className="font-semibold text-white">Spaced Repetition & Weakness Engine</div>
              <div className="text-xs text-slate-400">
                Solve each position 3 times over spaced intervals to achieve Mastery. Mastered positions return periodically for refresher testing.
              </div>
            </div>
          </div>

          {/* Quick Mastery Filters */}
          <div className="flex gap-1.5 overflow-x-auto pb-1 mb-2 text-xs">
            <button
              onClick={() => setFilter('all')}
              className={`px-2.5 py-1 rounded-full border transition-all text-xs font-medium ${
                filter === 'all'
                  ? 'bg-emerald-500/20 text-emerald-400 border-emerald-500/50'
                  : 'bg-slate-800 text-slate-400 border-slate-700 hover:border-slate-600'
              }`}
            >
              All ({puzzles.length})
            </button>
            <button
              onClick={() => setFilter('needs_work')}
              className={`px-2.5 py-1 rounded-full border transition-all text-xs font-medium ${
                filter === 'needs_work'
                  ? 'bg-rose-500/20 text-rose-400 border-rose-500/50'
                  : 'bg-slate-800 text-slate-400 border-slate-700 hover:border-slate-600'
              }`}
            >
              Needs Work
            </button>
            <button
              onClick={() => setFilter('reviewing')}
              className={`px-2.5 py-1 rounded-full border transition-all text-xs font-medium ${
                filter === 'reviewing'
                  ? 'bg-amber-500/20 text-amber-400 border-amber-500/50'
                  : 'bg-slate-800 text-slate-400 border-slate-700 hover:border-slate-600'
              }`}
            >
              Reviewing
            </button>
            <button
              onClick={() => setFilter('mastered')}
              className={`px-2.5 py-1 rounded-full border transition-all text-xs font-medium ${
                filter === 'mastered'
                  ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/50'
                  : 'bg-slate-800 text-slate-400 border-slate-700 hover:border-slate-600'
              }`}
            >
              Mastered (Refreshers)
            </button>
            <button
              onClick={() => setFilter('three_move')}
              className={`px-2.5 py-1 rounded-full border transition-all text-xs font-medium ${
                filter === 'three_move'
                  ? 'bg-cyan-500/20 text-cyan-400 border-cyan-500/50'
                  : 'bg-slate-800 text-slate-400 border-slate-700 hover:border-slate-600'
              }`}
            >
              3-Move Plans
            </button>
            <button
              onClick={() => setFilter('challenging')}
              className={`px-2.5 py-1 rounded-full border transition-all text-xs font-medium ${
                filter === 'challenging'
                  ? 'bg-rose-500/25 text-rose-300 border-rose-500/60 font-bold'
                  : 'bg-slate-800 text-slate-400 border-slate-700 hover:border-slate-600'
              }`}
            >
              ⚠️ Challenging Variations
            </button>
          </div>

          {filteredPuzzles.length === 0 ? (
            <div className="text-center py-8 text-slate-400 text-sm">
              No positions currently in this category.
            </div>
          ) : (
            filteredPuzzles.map((p) => {
              const isSelected = p.id === currentPuzzleId;
              const prog = progressMap[p.id];
              const consecutive = prog?.consecutiveSolves || 0;
              const status: MasteryStatus = prog?.status || 'needs_work';

              return (
                <div
                  key={p.id}
                  onClick={() => onSelectPuzzle(p)}
                  className={`puzzle-card ${isSelected ? 'puzzle-active' : ''}`}
                >
                  {/* Familiarity Level Badge */}
                  <div className="flex items-center justify-between mb-1.5">
                    <div className="flex items-center gap-1.5 flex-wrap">
                      {status === 'mastered' ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/40">
                          <CheckCircle size={11} className="text-emerald-400" />
                          MASTERED ({consecutive}/3 • Spaced Refresher)
                        </span>
                      ) : status === 'reviewing' ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/20 text-amber-300 border border-amber-500/40">
                          <Clock size={11} className="text-amber-400" />
                          REVIEWING ({consecutive}/3 Solves)
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold bg-rose-500/20 text-rose-300 border border-rose-500/40">
                          <AlertTriangle size={11} className="text-rose-400" />
                          NEEDS WORK ({consecutive}/3)
                        </span>
                      )}

                      {p.isThreeMovePlan && (
                        <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-semibold bg-cyan-500/20 text-cyan-300 border border-cyan-500/30">
                          <Flame size={10} /> 3-Move Plan
                        </span>
                      )}

                      {p.gameOutcome && (
                        <span className={`px-1.5 py-0.5 rounded text-[10px] font-semibold ${
                          p.gameOutcome === 'win'
                            ? 'bg-emerald-950 text-emerald-400 border border-emerald-800'
                            : p.gameOutcome === 'loss'
                            ? 'bg-red-950 text-red-400 border border-red-800'
                            : 'bg-slate-800 text-slate-300'
                        }`}>
                          {p.gameOutcome === 'win' ? 'Won Game Weakness' : p.gameOutcome === 'loss' ? 'Loss Blunder' : 'Draw'}
                        </span>
                      )}
                    </div>

                    <span className="puzzle-rating">⭐ {p.rating}</span>
                  </div>

                  <div className="puzzle-title">{p.title}</div>
                  
                  {p.playedBlunder && (
                    <div className="text-xs text-rose-300/90 font-mono bg-rose-950/40 px-2 py-1 rounded my-1 border border-rose-900/50 flex items-center gap-1">
                      <ShieldAlert size={12} className="text-rose-400 shrink-0" />
                      <span>Blunder in your game: <strong>{p.playedBlunder}</strong></span>
                    </div>
                  )}

                  <div className="puzzle-desc text-xs text-slate-300 mt-1">{p.description}</div>

                  <div className="puzzle-footer mt-2 pt-2 border-t border-slate-800">
                    <span className="puzzle-color-hint">
                      {p.playerColor === 'w' ? '⚪ White to Move' : '⚫ Black to Move'}
                    </span>
                    <ChevronRight size={16} className="text-slate-400" />
                  </div>
                </div>
              );
            })
          )}
        </div>
      ) : activeTab === 'archive' ? (
        <div className="puzzle-list">
          <div className="module-banner" style={{ background: 'rgba(6, 182, 212, 0.12)', borderColor: 'rgba(6, 182, 212, 0.3)' }}>
            <Archive size={18} className="text-cyan-400 shrink-0" />
            <div>
              <div className="font-semibold text-white">Personal Positional Archive</div>
              <div className="text-xs text-slate-400">
                Positions you struggle in. Test yourself on their optimal 3-move solutions whenever you want!
              </div>
            </div>
          </div>

          {savedPositions.length === 0 ? (
            <div className="p-8 text-center bg-slate-900/40 rounded-xl border border-slate-800 text-slate-400 space-y-2">
              <Bookmark size={28} className="mx-auto text-slate-500 opacity-60" />
              <div className="text-sm font-semibold text-slate-300">No Saved Positions Yet</div>
              <p className="text-xs text-slate-400 max-w-sm mx-auto">
                When you encounter a difficult position in your games or 3-move drills, click <strong>"Save to Archive"</strong> under the board to store it here for targeted mastery.
              </p>
            </div>
          ) : (
            savedPositions.map((pos) => {
              const isSelected = pos.id === currentPuzzleId;
              const dateStr = new Date(pos.createdAt).toLocaleDateString();

              return (
                <div
                  key={pos.id}
                  className={`puzzle-card ${isSelected ? 'puzzle-active' : ''} transition-all`}
                >
                  <div className="puzzle-meta">
                    <span className="puzzle-theme text-cyan-400 font-semibold flex items-center gap-1">
                      <Flame size={13} />
                      3-Move Plan Archive
                    </span>
                    <span className="text-[11px] text-slate-400 font-mono">{dateStr}</span>
                  </div>

                  <div className="puzzle-title text-sm font-bold text-white mb-1">
                    {pos.title}
                  </div>

                  {pos.solutionSan && pos.solutionSan.length > 0 && (
                    <div className="my-1.5 p-1.5 bg-slate-900/90 rounded border border-slate-700/80 font-mono text-xs flex items-center gap-1.5">
                      <span className="text-slate-400 text-[10px] uppercase tracking-wider">Best Line:</span>
                      <span className="text-emerald-400 font-bold">{pos.solutionSan.join(' ')}</span>
                    </div>
                  )}

                  {pos.notes && (
                    <div className="text-xs text-slate-300 italic mb-2">
                      "{pos.notes}"
                    </div>
                  )}

                  <div className="puzzle-footer mt-2 pt-2 border-t border-slate-800 flex items-center justify-between">
                    <span className="puzzle-color-hint text-xs text-slate-400">
                      {pos.playerColor === 'w' ? '⚪ White to Move' : '⚫ Black to Move'}
                    </span>

                    <div className="flex items-center gap-1.5">
                      {onDeleteSavedPosition && (
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            onDeleteSavedPosition(pos.id);
                          }}
                          className="action-btn text-xs py-1 px-2 text-rose-400 hover:bg-rose-950/60 hover:border-rose-700"
                          title="Remove from archive"
                        >
                          <Trash2 size={12} />
                        </button>
                      )}

                      <button
                        onClick={() => onSelectSavedPosition && onSelectSavedPosition(pos)}
                        className="action-btn action-btn-primary text-xs py-1 px-2.5 flex items-center gap-1 font-semibold"
                        title="Load & test yourself on this position"
                      >
                        <Play size={12} />
                        <span>Test Now</span>
                      </button>
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      ) : (
        <div className="opening-list">
          <div className="module-banner">
            <Award size={18} className="text-purple-400" />
            <div>
              <div className="font-semibold text-white">Grandmaster Repertoire</div>
              <div className="text-xs text-slate-400">Deep opening trees with core tactical heuristics</div>
            </div>
          </div>

          {openings.map((op) => (
            <div
              key={op.id}
              onClick={() => onSelectOpening(op)}
              className="opening-card"
            >
              <div className="opening-eco-badge">{op.eco}</div>
              <div className="opening-name">{op.name}</div>
              <div className="opening-desc">{op.description}</div>
              <div className="opening-ideas">
                {op.idealIdeas.map((idea, idx) => (
                  <span key={idx} className="idea-tag">• {idea}</span>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
