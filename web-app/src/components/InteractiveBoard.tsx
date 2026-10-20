import React from 'react';
import { Chess, Square } from 'chess.js';

export interface BoardArrow {
  from: string; // e.g. "e2"
  to: string;   // e.g. "e4"
  frequency?: number;
  winRate?: number;
}

interface ChessboardProps {
  chess: Chess;
  selectedSquare: Square | null;
  onSquareClick: (square: Square) => void;
  validMoves: string[];
  orientation?: 'w' | 'b';
  lastMove?: { from: string; to: string } | null;
  arrows?: BoardArrow[];
}

const PIECE_UNICODE: Record<string, string> = {
  wp: '♙', wn: '♘', wb: '♗', wr: '♖', wq: '♕', wk: '♔',
  bp: '♟', bn: '♞', bb: '♝', br: '♜', bq: '♛', bk: '♚',
};

const FILES = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
const RANKS = ['8', '7', '6', '5', '4', '3', '2', '1'];

export const InteractiveBoard: React.FC<ChessboardProps> = ({
  chess,
  selectedSquare,
  onSquareClick,
  validMoves,
  orientation = 'w',
  lastMove,
  arrows = []
}) => {
  const boardRanks = orientation === 'w' ? RANKS : [...RANKS].reverse();
  const boardFiles = orientation === 'w' ? FILES : [...FILES].reverse();

  // Helper to get square center in 800x800 coordinate space
  const getSquareCoord = (sq: string): { x: number; y: number } | null => {
    if (!sq || sq.length < 2) return null;
    const file = sq[0];
    const rank = sq[1];
    const fileIdx = boardFiles.indexOf(file);
    const rankIdx = boardRanks.indexOf(rank);
    if (fileIdx === -1 || rankIdx === -1) return null;
    return { x: fileIdx * 100 + 50, y: rankIdx * 100 + 50 };
  };

  return (
    <div className="chess-board-container">
      <div className="chess-board relative">
        {boardRanks.map((rank, rankIdx) =>
          boardFiles.map((file, fileIdx) => {
            const square = `${file}${rank}` as Square;
            const piece = chess.get(square);
            const isDark = (rankIdx + fileIdx) % 2 === 1;
            const isSelected = selectedSquare === square;
            const isValidTarget = validMoves.includes(square);
            const isLastMove = lastMove && (lastMove.from === square || lastMove.to === square);
            const isCheck = piece && piece.type === 'k' && chess.inCheck() && piece.color === chess.turn();

            return (
              <div
                key={square}
                onClick={() => onSquareClick(square)}
                className={`square ${isDark ? 'dark-sq' : 'light-sq'} ${
                  isSelected ? 'selected-sq' : ''
                } ${isLastMove ? 'last-move-sq' : ''} ${isCheck ? 'in-check-sq' : ''}`}
                data-square={square}
              >
                {/* Coordinates */}
                {file === (orientation === 'w' ? 'a' : 'h') && (
                  <span className="coord rank-coord">{rank}</span>
                )}
                {rank === (orientation === 'w' ? '1' : '8') && (
                  <span className="coord file-coord">{file}</span>
                )}

                {/* Valid Move Indicator */}
                {isValidTarget && (
                  <div className={piece ? 'capture-ring' : 'valid-dot'} />
                )}

                {/* Piece */}
                {piece && (
                  <span
                    className={`piece ${piece.color === 'w' ? 'white-piece' : 'black-piece'} ${
                      lastMove && lastMove.to === square ? 'piece-arrival' : ''
                    }`}
                  >
                    {PIECE_UNICODE[`${piece.color}${piece.type}`]}
                  </span>
                )}
              </div>
            );
          })
        )}

        {/* Candidate Move Visual Arrows Overlay (OpeningTree style) */}
        {arrows.length > 0 && (
          <svg
            viewBox="0 0 800 800"
            className="absolute inset-0 w-full h-full pointer-events-none"
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: '100%',
              pointerEvents: 'none',
              zIndex: 25
            }}
          >
            <defs>
              <marker
                id="arrow-head-win"
                markerWidth="8"
                markerHeight="8"
                refX="5"
                refY="4"
                orient="auto"
                markerUnits="strokeWidth"
              >
                <polygon points="1 1, 7 4, 1 7" fill="#10b981" />
              </marker>
              <marker
                id="arrow-head-leak"
                markerWidth="8"
                markerHeight="8"
                refX="5"
                refY="4"
                orient="auto"
                markerUnits="strokeWidth"
              >
                <polygon points="1 1, 7 4, 1 7" fill="#f43f5e" />
              </marker>
              <marker
                id="arrow-head-default"
                markerWidth="8"
                markerHeight="8"
                refX="5"
                refY="4"
                orient="auto"
                markerUnits="strokeWidth"
              >
                <polygon points="1 1, 7 4, 1 7" fill="#38bdf8" />
              </marker>
            </defs>

            {arrows.map((arr, idx) => {
              const start = getSquareCoord(arr.from);
              const end = getSquareCoord(arr.to);
              if (!start || !end) return null;

              // Calculate angle and shorten line slightly so arrowhead doesn't overshoot square center
              const dx = end.x - start.x;
              const dy = end.y - start.y;
              const len = Math.sqrt(dx * dx + dy * dy);
              if (len === 0) return null;

              // Shorten by 28 units (out of 100 per square) so arrowhead sits cleanly inside target square
              const shorten = 28;
              const targetX = end.x - (dx / len) * shorten;
              const targetY = end.y - (dy / len) * shorten;

              const isWin = (arr.winRate ?? 50) >= 55;
              const isLeak = (arr.winRate ?? 50) < 42;
              const strokeColor = isWin
                ? '#10b981'
                : isLeak
                ? '#f43f5e'
                : '#38bdf8';
              const markerId = isWin
                ? 'url(#arrow-head-win)'
                : isLeak
                ? 'url(#arrow-head-leak)'
                : 'url(#arrow-head-default)';
              const strokeWidth = Math.max(9, Math.min(17, ((arr.frequency ?? 50) / 100) * 19));

              return (
                <line
                  key={`${arr.from}-${arr.to}-${idx}`}
                  x1={start.x}
                  y1={start.y}
                  x2={targetX}
                  y2={targetY}
                  stroke={strokeColor}
                  strokeWidth={strokeWidth}
                  strokeLinecap="round"
                  opacity={0.88}
                  markerEnd={markerId}
                />
              );
            })}
          </svg>
        )}
      </div>
    </div>
  );
};
