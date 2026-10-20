import React from 'react';
import { ChessComGame } from '../services/chessComService';
import { Swords, ExternalLink, Calendar, User, ChevronRight, Sparkles, RefreshCw, Trophy } from 'lucide-react';

interface RecentGamesListProps {
  games: ChessComGame[];
  username: string;
  onAnalyzeGame: (game: ChessComGame) => void;
  activeGameUrl?: string | null;
  onOpenConnectModal?: () => void;
  isSyncing?: boolean;
}

export const RecentGamesList: React.FC<RecentGamesListProps> = ({
  games,
  username,
  onAnalyzeGame,
  activeGameUrl,
  onOpenConnectModal,
  isSyncing
}) => {
  const recentGames = games.slice(0, 5);

  if (!username) {
    return (
      <div className="empty-analysis-state">
        <Swords size={48} className="text-cyan-400 mb-3" />
        <h3 className="text-lg font-bold text-white mb-1">Recent Games</h3>
        <p className="text-sm text-slate-400 max-w-md text-center mb-4">
          Connect your Chess.com account to view your last 5 matches with opponent usernames, game results, and launch move-by-move engine analysis.
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

  if (recentGames.length === 0) {
    return (
      <div className="empty-analysis-state">
        <Swords size={48} className="text-cyan-400 mb-3" />
        <h3 className="text-lg font-bold text-white mb-1">No Games Found</h3>
        <p className="text-sm text-slate-400 max-w-md text-center mb-4">
          {isSyncing
            ? `Syncing games from Chess.com for @${username}...`
            : `No recent games retrieved for @${username}. Try resyncing from your profile header.`}
        </p>
      </div>
    );
  }

  const cleanUser = username.trim().toLowerCase();

  return (
    <div className="recent-games-section">
      <div className="recent-games-header">
        <div className="flex items-center gap-2">
          <Swords size={18} className="text-cyan-400" />
          <h3 className="recent-games-title">Last 5 Games (@{username})</h3>
        </div>
        <span className="text-[11px] text-slate-400 font-normal">Click Analyze to review full game</span>
      </div>

      <div className="recent-games-grid">
        {recentGames.map((game, idx) => {
          const isWhite = game.white.username.toLowerCase() === cleanUser;
          const myResult = isWhite ? game.white.result : game.black.result;
          const opponent = isWhite ? game.black : game.white;
          const myPlayer = isWhite ? game.white : game.black;

          const isWin = myResult === 'win';
          const isDraw = ['agreed', 'repetition', 'stalemate', 'timevsinsufficient', 'insufficient', '50move'].includes(myResult);
          const outcomeText = isWin ? 'Won' : isDraw ? 'Draw' : 'Loss';
          const outcomeClass = isWin ? 'outcome-win' : isDraw ? 'outcome-draw' : 'outcome-loss';

          // Format date & time control
          const dateStr = game.end_time ? new Date(game.end_time * 1000).toLocaleDateString(undefined, {
            month: 'short',
            day: 'numeric'
          }) : '';
          const timeClass = (game as any).time_class || game.time_control || 'game';
          const isSelected = activeGameUrl === game.url;

          return (
            <div
              key={game.url || idx}
              className={`recent-game-card ${isSelected ? 'recent-game-card-active' : ''}`}
            >
              <div className="recent-game-info">
                <div className="flex items-center gap-2 mb-1 flex-wrap">
                  <span className={`game-outcome-badge ${outcomeClass}`}>
                    {outcomeText}
                  </span>
                  <span className="game-color-badge" title={`You played as ${isWhite ? 'White' : 'Black'}`}>
                    <span
                      className="color-dot"
                      style={{ backgroundColor: isWhite ? '#ffffff' : '#1e293b', border: '1px solid #64748b' }}
                    />
                    {isWhite ? 'White' : 'Black'}
                  </span>
                  <span className="game-time-badge capitalize">
                    {timeClass}
                  </span>
                </div>

                <div className="recent-game-opponent">
                  <span className="text-slate-400 text-xs flex items-center gap-1">
                    <User size={13} className="text-slate-400 shrink-0" />
                    vs
                  </span>
                  <span className="opponent-name" title={`Rating: ${opponent.rating}`}>
                    @{opponent.username}
                  </span>
                  <span className="opponent-rating font-mono">
                    ({opponent.rating})
                  </span>
                </div>

                {dateStr && (
                  <div className="text-[11px] text-slate-500 flex items-center gap-1 mt-0.5">
                    <Calendar size={11} />
                    <span>{dateStr}</span>
                    <span>•</span>
                    <span>Your rating: {myPlayer.rating}</span>
                  </div>
                )}
              </div>

              <div className="recent-game-actions">
                <button
                  type="button"
                  className="analyze-game-btn"
                  onClick={() => onAnalyzeGame(game)}
                  title="Load full game into Game Review analysis board"
                >
                  <Swords size={14} />
                  <span>Analyze</span>
                  <ChevronRight size={14} className="opacity-70" />
                </button>

                {game.url && (
                  <a
                    href={game.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="chesscom-link-btn"
                    title="View on Chess.com"
                  >
                    <ExternalLink size={13} />
                  </a>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
