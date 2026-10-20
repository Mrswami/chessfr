import React from 'react';
import knightImg from '../assets/justtheknight.png';

interface LoadingScreenProps {
  statusMessage?: string | null;
  subMessage?: string;
}

/**
 * Dedicated Full-Screen Dimmed Loading Screen
 * Centers user's knight emblem, provides clear "Loading..." text, and dims the entire screen
 * with pointer-events-auto and backdrop-blur to prevent clicks/interactions while initial games
 * or cloud profiles are synchronizing.
 */
export const DedicatedLoadingOverlay: React.FC<LoadingScreenProps> = ({
  statusMessage = 'Analyzing games & synchronizing opening tree...',
  subMessage = 'Please wait while positions, blunders & 3-move response patterns load'
}) => {
  return (
    <div
      className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/85 backdrop-blur-md select-none transition-all duration-300"
      style={{ pointerEvents: 'all' }}
    >
      <div className="relative flex flex-col items-center max-w-sm sm:max-w-md px-8 py-9 mx-4 text-center rounded-3xl bg-slate-900/95 border border-cyan-500/40 shadow-[0_0_80px_rgba(6,182,212,0.35)]">
        
        {/* Holographic Glowing Emblem Frame with Rotating Aura */}
        <div className="relative w-36 h-36 mb-6 flex items-center justify-center">
          {/* Outer glowing pulsing ring */}
          <div className="absolute inset-0 rounded-full border-2 border-cyan-400/40 animate-ping opacity-25" />
          
          {/* Middle rotating dashed halo */}
          <div
            className="absolute inset-[-4px] rounded-full border-2 border-dashed border-cyan-400/60 animate-spin"
            style={{ animationDuration: '8s' }}
          />
          
          {/* Inner counter-rotating violet ring */}
          <div
            className="absolute inset-[-10px] rounded-full border border-violet-500/40 animate-spin"
            style={{ animationDirection: 'reverse', animationDuration: '6s' }}
          />

          {/* Central User Knight Emblem (justtheknight.png) */}
          <div className="w-28 h-28 rounded-2xl overflow-hidden p-1.5 bg-slate-950/70 border border-cyan-400/60 shadow-[0_0_30px_rgba(6,182,212,0.7)] flex items-center justify-center relative z-10">
            <img
              src={knightImg}
              alt="Loading Knight"
              className="w-full h-full object-contain filter drop-shadow-[0_0_12px_rgba(6,182,212,0.6)] animate-pulse"
              style={{ animationDuration: '2.5s' }}
            />
          </div>
        </div>

        {/* Prominent Loading Title */}
        <div className="flex items-center gap-2 mb-2">
          <span className="w-2.5 h-2.5 rounded-full bg-cyan-400 animate-ping inline-block" />
          <h2 className="text-xl sm:text-2xl font-black text-white tracking-wide uppercase font-mono">
            Loading...
          </h2>
          <span className="w-2.5 h-2.5 rounded-full bg-cyan-400 animate-ping inline-block" />
        </div>

        {/* Engine Sync Subheading */}
        <p className="text-xs sm:text-sm font-bold text-cyan-300 mb-2 tracking-tight">
          chessfr Engine Sync in Progress
        </p>

        {/* Dynamic Status Detail */}
        <p className="text-xs sm:text-sm text-slate-200 font-medium leading-relaxed max-w-xs mb-3">
          {statusMessage}
        </p>

        {subMessage && (
          <div className="text-[11px] text-slate-400 font-mono tracking-wide px-3.5 py-1.5 rounded-lg bg-slate-950/80 border border-slate-800/90 mb-4">
            {subMessage}
          </div>
        )}

        {/* Please Wait Alert Pill */}
        <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-cyan-950/80 border border-cyan-500/40 text-cyan-300 text-[11px] font-semibold">
          <span>Screen locked until sync finishes</span>
        </div>

        {/* Shimmering Progress Bar */}
        <div className="w-full h-1.5 mt-5 bg-slate-800 rounded-full overflow-hidden relative">
          <div className="h-full bg-gradient-to-r from-cyan-500 via-indigo-400 to-cyan-300 rounded-full w-3/4 animate-pulse" />
        </div>
      </div>
    </div>
  );
};

