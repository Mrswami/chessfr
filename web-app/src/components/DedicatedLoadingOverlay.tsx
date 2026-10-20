import React from 'react';
import knightImg from '../assets/justtheknight.png';

interface LoadingScreenProps {
  statusMessage?: string | null;
  subMessage?: string;
}

/**
 * Dedicated Full-Screen Dimmed Loading Screen
 * Centers user's knight emblem, displays prominent "LOADING..." text,
 * and dims the entire screen with z-index 99999 and pointer-events all
 * so users cannot click or interact with the website until sync finishes.
 */
export const DedicatedLoadingOverlay: React.FC<LoadingScreenProps> = ({
  statusMessage = 'Analyzing games & synchronizing opening tree...',
  subMessage = 'Please wait while positions, blunders & 3-move response patterns load'
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

        {/* Interaction Locked Badge */}
        <div className="loading-lock-pill">
          <span>🔒 Screen locked until sync finishes</span>
        </div>

        {/* Indeterminate Shimmering Progress Bar */}
        <div className="loading-progress-bar-wrap">
          <div className="loading-progress-bar-fill" />
        </div>
      </div>
    </div>
  );
};

