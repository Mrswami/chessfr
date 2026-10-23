import React from 'react';
import knightImg from '../assets/justtheknight.png';

interface LoadingScreenProps {
  statusMessage?: string | null;
  subMessage?: string;
  onDismiss?: () => void;
}

export const DedicatedLoadingOverlay: React.FC<LoadingScreenProps> = ({
  statusMessage = 'Analyzing games & synchronizing opening tree...',
  subMessage = 'Please wait while positions, blunders & 3-move response patterns load',
  onDismiss
}) => {
  return (
    <div className="dedicated-loading-backdrop" aria-busy="true" aria-live="polite">
      <div className="loading-modal-card">
        {/* Holographic Glowing Emblem Frame with Rotating Aura */}
        <div className="loading-emblem-wrap">
          <div className="loading-emblem-halo" />
          <div className="loading-emblem-glow" />
          <div className="loading-knight-box">
            <img
              src={knightImg}
              alt="Loading Knight Emblem"
              className="loading-knight-img"
            />
          </div>
        </div>

        {/* Prominent Loading Title */}
        <div className="loading-title-row">
          <span className="loading-beacon" />
          <h2 className="loading-main-text">
            Loading...
          </h2>
          <span className="loading-beacon" />
        </div>

        {/* Engine Sync Subheading */}
        <div className="loading-subheading">
          chessfr Engine Sync in Progress
        </div>

        {/* Dynamic Status Detail */}
        {statusMessage && (
          <p className="loading-status-detail">
            {statusMessage}
          </p>
        )}

        {/* Informative Submessage Badge */}
        {subMessage && (
          <div className="loading-submessage-badge">
            {subMessage}
          </div>
        )}

        {/* Indeterminate Shimmering Progress Bar */}
        <div className="loading-progress-bar-wrap">
          <div className="loading-progress-bar-fill" />
        </div>

        {onDismiss && (
          <button
            type="button"
            onClick={onDismiss}
            className="mt-3 px-3 py-1 rounded-lg text-xs font-semibold text-slate-400 hover:text-white bg-slate-800/80 hover:bg-slate-700/80 border border-slate-700 transition-colors"
          >
            Continue in Background
          </button>
        )}
      </div>
    </div>
  );
};

