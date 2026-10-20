import React from 'react';
import knightImg from '../assets/loading-knight.png';

interface LoadingScreenProps {
  statusMessage?: string | null;
  subMessage?: string;
}

export const DedicatedLoadingOverlay: React.FC<LoadingScreenProps> = ({
  statusMessage = 'Analyzing games & synchronizing opening tree...',
  subMessage = 'Crunching blunders, 3-move response patterns & master evaluations'
}) => {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/85 backdrop-blur-md transition-all duration-300">
      <div className="relative flex flex-col items-center max-w-sm px-6 py-8 mx-4 text-center rounded-2xl bg-slate-900/90 border border-cyan-500/30 shadow-[0_0_50px_rgba(6,182,212,0.25)]">
        
        {/* Holographic Glowing Emblem with Rotation Rings */}
        <div className="relative w-28 h-28 mb-5 flex items-center justify-center">
          {/* Outer glowing pulsed ring */}
          <div className="absolute inset-0 rounded-full border-2 border-cyan-400/40 animate-ping opacity-30" />
          
          {/* Middle rotating dash ring */}
          <div className="absolute inset-1 rounded-full border-2 border-dashed border-cyan-400/60 animate-spin" style={{ animationDuration: '6s' }} />
          
          {/* Counter-rotating violet glow ring */}
          <div className="absolute inset-3 rounded-full border border-violet-500/50 animate-spin" style={{ animationDirection: 'reverse', animationDuration: '4s' }} />

          {/* Central AI Knight Icon generated via OpenArt AI */}
          <img
            src={knightImg}
            alt="Loading Chess Knight"
            className="w-20 h-20 rounded-full object-cover shadow-[0_0_20px_rgba(6,182,212,0.8)] border border-cyan-400/50 relative z-10"
          />
        </div>

        {/* Dynamic Titles */}
        <h3 className="text-base sm:text-lg font-bold text-white tracking-tight mb-1.5 flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-cyan-400 animate-pulse inline-block" />
          <span>chessfr Engine Sync</span>
        </h3>
        
        <p className="text-xs sm:text-sm text-cyan-200 font-medium leading-relaxed mb-3">
          {statusMessage}
        </p>

        {subMessage && (
          <div className="text-[11px] text-slate-400 font-mono tracking-wide px-3 py-1.5 rounded-lg bg-slate-950/60 border border-slate-800">
            {subMessage}
          </div>
        )}

        {/* Shimmering Progress Bar */}
        <div className="w-full h-1.5 mt-5 bg-slate-800 rounded-full overflow-hidden relative">
          <div className="h-full bg-gradient-to-r from-cyan-500 via-indigo-500 to-cyan-400 rounded-full w-2/3 animate-pulse" />
        </div>
      </div>
    </div>
  );
};
