import React, { useState } from 'react';
import { TreeMoveStats, OpeningTree } from '../utils/openingTreeBuilder';
import {
  GitBranch,
  RotateCcw,
  ChevronLeft,
  Sparkles,
  Flame,
  Award,
  Filter,
  RefreshCw,
  SlidersHorizontal,
  Eye,
  EyeOff
} from 'lucide-react';
import { FetchGamesOptions } from '../services/chessComService';

interface OpeningTreePanelProps {
  tree: OpeningTree | null;
  totalGamesLoaded: number;
  currentFen: string;
  candidateMoves: TreeMoveStats[];
  currentLineSan: string[];
  activeColor: 'white' | 'black';
  onColorChange: (color: 'white' | 'black') => void;
  onSelectMove: (move: TreeMoveStats) => void;
  onStepBack: () => void;
  onResetTree: () => void;
  onGenerateDrillForPosition: () => void;
  chessComUsername: string;
  onOpenConnectModal: () => void;
  currentFilters: FetchGamesOptions;
  onApplyFilters: (filters: FetchGamesOptions) => void;
  isSyncing: boolean;
  showArrows: boolean;
  onToggleArrows: () => void;
}

export const OpeningTreePanel: React.FC<OpeningTreePanelProps> = ({
  tree,
  totalGamesLoaded,
  currentFen,
  candidateMoves,
  currentLineSan,
  activeColor,
  onColorChange,
  onSelectMove,
  onStepBack,
  onResetTree,
  onGenerateDrillForPosition,
  chessComUsername,
  onOpenConnectModal,
  currentFilters,
  onApplyFilters,
  isSyncing,
  showArrows,
  onToggleArrows
}) => {
  const [showFilterDrawer, setShowFilterDrawer] = useState(false);
  const [selectedLimit, setSelectedLimit] = useState<number>(currentFilters.limit ?? 100);
  const [selectedTimeControl, setSelectedTimeControl] = useState<'all' | 'rapid' | 'blitz' | 'bullet' | 'daily'>(
    currentFilters.timeControl ?? 'all'
  );
  const [selectedRatedOnly, setSelectedRatedOnly] = useState<boolean>(currentFilters.ratedOnly ?? false);
  const [selectedColor, setSelectedColor] = useState<'all' | 'white' | 'black'>(currentFilters.color ?? 'all');
  const [selectedStartDate, setSelectedStartDate] = useState<string>(currentFilters.startDate ?? '');
  const [selectedEndDate, setSelectedEndDate] = useState<string>(currentFilters.endDate ?? '');

  const totalPositionGames = candidateMoves.reduce((acc, m) => acc + m.gamesCount, 0);

  const handleApply = () => {
    onApplyFilters({
      limit: selectedLimit,
      timeControl: selectedTimeControl,
      ratedOnly: selectedRatedOnly,
      color: selectedColor,
      startDate: selectedStartDate || undefined,
      endDate: selectedEndDate || undefined
    });
    setShowFilterDrawer(false);
  };

  return (
    <div className="opening-tree-panel">
      {/* Header Banner */}
      <div className="tree-header-banner">
        <div className="flex items-center justify-between flex-wrap gap-2">
          <div className="flex items-center gap-2">
            <GitBranch size={18} className="text-emerald-400" />
            <div>
              <div className="font-bold text-white text-sm">Personal Opening Tree</div>
              <div className="text-xs text-slate-400">
                {totalGamesLoaded > 0 ? (
                  <span>
                    Analyzed <strong className="text-emerald-400">{totalGamesLoaded} games</strong> across archives
                  </span>
                ) : (
                  'Explore every branch of your repertoire with real historical win rates'
                )}
              </div>
            </div>
          </div>

          {/* Quick Actions & Filter Toggle */}
          <div className="flex items-center gap-1.5">
            <button
              onClick={() => setShowFilterDrawer(!showFilterDrawer)}
              className={`action-btn text-xs py-1 px-2.5 flex items-center gap-1.5 transition-all ${
                showFilterDrawer || (currentFilters.limit && currentFilters.limit > 100)
                  ? 'bg-cyan-950 text-cyan-300 border-cyan-700'
                  : ''
              }`}
              title="Configure filters (games count, time control, rated mode)"
            >
              <SlidersHorizontal size={13} />
              <span>Filters</span>
            </button>

            <button
              onClick={onToggleArrows}
              className={`action-btn text-xs py-1 px-2 flex items-center gap-1 ${
                showArrows ? 'text-emerald-300' : 'text-slate-500'
              }`}
              title={showArrows ? 'Hide board arrows' : 'Show board arrows'}
            >
              {showArrows ? <Eye size={13} /> : <EyeOff size={13} />}
              <span>Arrows</span>
            </button>

            {/* Color Switcher */}
            <div className="flex items-center bg-slate-900 border border-slate-700 rounded-lg p-0.5 text-xs font-semibold">
              <button
                onClick={() => onColorChange('white')}
                className={`px-2 py-0.5 rounded transition-all flex items-center gap-1 ${
                  activeColor === 'white'
                    ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/40'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                <span>⚪ White</span>
              </button>
              <button
                onClick={() => onColorChange('black')}
                className={`px-2 py-0.5 rounded transition-all flex items-center gap-1 ${
                  activeColor === 'black'
                    ? 'bg-purple-500/20 text-purple-300 border border-purple-500/40'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                <span>⚫ Black</span>
              </button>
            </div>
          </div>
        </div>

        {/* Expandable OpeningTree Filters Drawer */}
        {showFilterDrawer && (
          <div className="mt-3 p-3 bg-slate-900/95 border border-slate-700 rounded-xl text-xs space-y-3">
            <div className="flex items-center justify-between pb-2 border-b border-slate-800">
              <span className="font-semibold text-slate-200 flex items-center gap-1.5">
                <Filter size={13} className="text-cyan-400" />
                <span>Archive & Game Extraction Filters</span>
              </span>
              <span className="text-[11px] text-slate-400">openingtree.com filters</span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              {/* Download / Game Limit */}
              <div>
                <label className="text-slate-400 block mb-1 font-medium">Download Limit</label>
                <select
                  value={selectedLimit}
                  onChange={(e) => setSelectedLimit(Number(e.target.value))}
                  className="w-full bg-slate-800 text-slate-200 border border-slate-700 rounded px-2 py-1"
                >
                  <option value={50}>50 Games (Fastest)</option>
                  <option value={100}>100 Games (Standard)</option>
                  <option value={200}>200 Games (Deep)</option>
                  <option value={500}>500 Games (Extensive)</option>
                  <option value={1000}>1000 Games (Comprehensive)</option>
                </select>
              </div>

              {/* Played As Color Filter */}
              <div>
                <label className="text-slate-400 block mb-1 font-medium">Played As Color</label>
                <select
                  value={selectedColor}
                  onChange={(e) => setSelectedColor(e.target.value as any)}
                  className="w-full bg-slate-800 text-slate-200 border border-slate-700 rounded px-2 py-1"
                >
                  <option value="all">Both (White & Black)</option>
                  <option value="white">White Only</option>
                  <option value="black">Black Only</option>
                </select>
              </div>

              {/* Time Control */}
              <div>
                <label className="text-slate-400 block mb-1 font-medium">Time Control</label>
                <select
                  value={selectedTimeControl}
                  onChange={(e) => setSelectedTimeControl(e.target.value as any)}
                  className="w-full bg-slate-800 text-slate-200 border border-slate-700 rounded px-2 py-1"
                >
                  <option value="all">All Time Controls</option>
                  <option value="rapid">Rapid Only</option>
                  <option value="blitz">Blitz Only</option>
                  <option value="bullet">Bullet Only</option>
                  <option value="daily">Daily / Classical</option>
                </select>
              </div>

              {/* Date Range: From */}
              <div>
                <label className="text-slate-400 block mb-1 font-medium">Start Date (From)</label>
                <input
                  type="date"
                  value={selectedStartDate}
                  onChange={(e) => setSelectedStartDate(e.target.value)}
                  className="w-full bg-slate-800 text-slate-200 border border-slate-700 rounded px-2 py-1 text-xs"
                />
              </div>

              {/* Date Range: To */}
              <div>
                <label className="text-slate-400 block mb-1 font-medium">End Date (To)</label>
                <input
                  type="date"
                  value={selectedEndDate}
                  onChange={(e) => setSelectedEndDate(e.target.value)}
                  className="w-full bg-slate-800 text-slate-200 border border-slate-700 rounded px-2 py-1 text-xs"
                />
              </div>

              {/* Game Mode */}
              <div>
                <label className="text-slate-400 block mb-1 font-medium">Rating Type</label>
                <select
                  value={selectedRatedOnly ? 'rated' : 'all'}
                  onChange={(e) => setSelectedRatedOnly(e.target.value === 'rated')}
                  className="w-full bg-slate-800 text-slate-200 border border-slate-700 rounded px-2 py-1"
                >
                  <option value="all">Rated & Casual</option>
                  <option value="rated">Rated Only</option>
                </select>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t border-slate-800">
              <button
                type="button"
                onClick={() => setShowFilterDrawer(false)}
                className="action-btn text-xs py-1 px-3"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleApply}
                disabled={isSyncing}
                className="action-btn action-btn-primary text-xs py-1 px-3.5 flex items-center gap-1.5"
              >
                <RefreshCw size={12} className={isSyncing ? 'animate-spin' : ''} />
                <span>{isSyncing ? 'Fetching Archives...' : 'Fetch & Rebuild Tree'}</span>
              </button>
            </div>
          </div>
        )}

        {/* Current Line Breadcrumb & Controls */}
        <div className="tree-breadcrumb-bar mt-3 pt-2.5 border-t border-slate-800 flex items-center justify-between flex-wrap gap-2">
          <div className="flex items-center gap-2 flex-wrap text-xs">
            <span className="text-slate-400 font-medium">Line:</span>
            {currentLineSan.length === 0 ? (
              <span className="text-slate-300 px-2 py-0.5 bg-slate-800/80 rounded border border-slate-700/60 font-mono">
                Starting Position
              </span>
            ) : (
              <div className="flex items-center gap-1.5 flex-wrap">
                {currentLineSan.map((san, idx) => {
                  const moveNum = Math.floor(idx / 2) + 1;
                  const isWhiteMove = idx % 2 === 0;
                  return (
                    <span key={idx} className="inline-flex items-center font-mono">
                      {isWhiteMove && <span className="text-slate-500 mr-1">{moveNum}.</span>}
                      <strong className="px-1.5 py-0.5 bg-cyan-950/60 text-cyan-300 rounded border border-cyan-800/60 font-semibold">
                        {san}
                      </strong>
                    </span>
                  );
                })}
              </div>
            )}
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={onStepBack}
              disabled={currentLineSan.length === 0}
              className="action-btn text-xs py-1 px-2.5"
              title="Step Back 1 Move"
            >
              <ChevronLeft size={14} />
              <span>Back</span>
            </button>
            <button
              onClick={onResetTree}
              disabled={currentLineSan.length === 0}
              className="action-btn text-xs py-1 px-2.5"
              title="Reset to Starting Position"
            >
              <RotateCcw size={14} />
              <span>Reset</span>
            </button>
          </div>
        </div>
      </div>

      {/* Candidate Moves Table (openingtree.com style) */}
      {!chessComUsername ? (
        <div className="p-6 text-center bg-slate-900/60 rounded-xl border border-slate-800 my-3">
          <Award size={32} className="mx-auto text-cyan-400 mb-2 opacity-80" />
          <h4 className="text-white font-semibold text-sm mb-1">Connect Your Chess.com Account</h4>
          <p className="text-xs text-slate-400 max-w-md mx-auto mb-3">
            ChessFr will analyze your games to construct your personal interactive move tree, highlighting high win-rate variations and leaky opening lines.
          </p>
          <button
            onClick={onOpenConnectModal}
            className="action-btn action-btn-primary mx-auto text-xs py-1.5 px-3"
          >
            Connect Handle
          </button>
        </div>
      ) : candidateMoves.length === 0 ? (
        <div className="p-6 text-center bg-slate-900/40 rounded-xl border border-slate-800 my-3">
          <p className="text-xs text-slate-400">
            No games in your filtered dataset reached this exact branch. Try stepping back, or increase your download limit in Filters.
          </p>
        </div>
      ) : (
        <div className="tree-table-container my-2">
          <table className="tree-table">
            <thead>
              <tr>
                <th className="text-left" style={{ width: '22%' }}>Move</th>
                <th className="text-center" style={{ width: '12%' }}>Games</th>
                <th className="text-center" style={{ width: '38%' }}>Results (W / D / L)</th>
                <th className="text-right" style={{ width: '10%' }}>Win %</th>
                <th className="text-right" style={{ width: '9%' }}>Freq</th>
                <th className="text-right" style={{ width: '9%' }}>Opp Avg</th>
              </tr>
            </thead>
            <tbody>
              {candidateMoves.map((m) => {
                const isHighWinRate = m.winRate >= 55;
                const isLeaking = m.winRate < 42 && m.gamesCount >= 2;

                return (
                  <tr
                    key={m.san}
                    onClick={() => onSelectMove(m)}
                    className="tree-row hover:bg-slate-800/60 cursor-pointer transition-all"
                  >
                    {/* Move SAN with clean spacing */}
                    <td className="font-bold text-white font-mono text-sm py-2">
                      <div className="flex items-center gap-2 flex-nowrap whitespace-nowrap">
                        <span className="text-cyan-300 font-bold min-w-[28px]">{m.san}</span>
                        {isHighWinRate && (
                          <span className="inline-flex items-center px-1.5 py-0.5 bg-emerald-950/80 text-emerald-400 rounded text-[9px] border border-emerald-700/60 font-sans font-semibold tracking-wide ml-1">
                            High Win
                          </span>
                        )}
                        {isLeaking && (
                          <span className="inline-flex items-center px-1.5 py-0.5 bg-rose-950/80 text-rose-400 rounded text-[9px] border border-rose-700/60 font-sans font-semibold tracking-wide ml-1">
                            Leaking
                          </span>
                        )}
                      </div>
                    </td>

                    {/* Games Count */}
                    <td className="text-center font-mono text-xs text-slate-300 py-2">
                      {m.gamesCount}
                    </td>

                    {/* Visual Segmented Result Bar */}
                    <td className="px-2 py-2">
                      <div className="result-bar-container">
                        <div
                          className="result-segment result-win"
                          style={{ width: `${m.winRate}%` }}
                          title={`Wins: ${m.wins} (${m.winRate}%)`}
                        />
                        <div
                          className="result-segment result-draw"
                          style={{ width: `${m.drawRate}%` }}
                          title={`Draws: ${m.draws} (${m.drawRate}%)`}
                        />
                        <div
                          className="result-segment result-loss"
                          style={{ width: `${m.lossRate}%` }}
                          title={`Losses: ${m.losses} (${m.lossRate}%)`}
                        />
                      </div>
                      <div className="flex justify-between text-[10px] text-slate-400 font-mono mt-1">
                        <span className="text-emerald-400 font-semibold">{m.wins}W</span>
                        <span className="text-slate-400">{m.draws}D</span>
                        <span className="text-rose-400 font-semibold">{m.losses}L</span>
                      </div>
                    </td>

                    {/* Win Rate */}
                    <td className="text-right font-mono font-bold text-xs">
                      <span className={m.winRate >= 50 ? 'text-emerald-400' : 'text-rose-400'}>
                        {m.winRate}%
                      </span>
                    </td>

                    {/* Frequency */}
                    <td className="text-right font-mono text-xs text-slate-400">
                      {m.frequency}%
                    </td>

                    {/* Opponent Rating */}
                    <td className="text-right font-mono text-xs text-slate-400">
                      {m.avgOpponentRating}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Aggregate Drills & Training Button */}
      {candidateMoves.length > 0 && (
        <div className="mt-3 p-3 bg-cyan-950/30 border border-cyan-800/40 rounded-xl flex items-center justify-between flex-wrap gap-2">
          <div className="flex items-center gap-2">
            <Flame size={16} className="text-cyan-400 shrink-0" />
            <div className="text-xs text-slate-300">
              <strong className="text-cyan-200">Repertoire Practice:</strong> Generate targeted 3-move training drills for this exact branch.
            </div>
          </div>
          <button
            onClick={onGenerateDrillForPosition}
            className="action-btn text-xs py-1.5 px-3 bg-cyan-600/30 text-cyan-300 border border-cyan-500/50 hover:bg-cyan-600/50"
          >
            <Sparkles size={13} />
            <span>Generate 3-Move Drills</span>
          </button>
        </div>
      )}
    </div>
  );
};
