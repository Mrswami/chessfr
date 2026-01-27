# ChessUp Pro - Final Protocol Understanding

## What Works ✅
- **E9 Events**: Piece lifted/placed (sends piece IDs, not coordinates)
- **B2 Packets**: Status reports
- **BB Packets**: Heartbeat
- **Connection**: Stable BLE connection

## What Doesn't Work ❌
- **71 01 Command**: Returns incomplete data (10 bytes instead of 66+)
- **40 00 Command**: Rejected with NACK (26 00 04 40)
- **State Polling**: Board doesn't support full position requests

## The Solution: Event-Driven Architecture

Since we can't poll the board state, we must:

1. **Start from known position** (standard chess start)
2. **Track E9 events**:
   - Piece ID X lifted
   - Piece ID Y placed
3. **Use chess.dart engine** to:
   - Determine which legal move was made
   - Update internal game state
   - Generate PGN notation (e4, Nf3, etc.)
4. **Update visual board** from chess engine's FEN

### Implementation Sketch
```dart
import 'package:chess/chess.dart' as chess;

chess.Chess game = chess.Chess();

// On E9 piece placed:
void onPiecePlaced(int pieceId) {
  // Get all legal moves
  List<chess.Move> legalMoves = game.generate_moves();
  
  // User made ONE of these moves
  // We deduce which by comparing piece positions
  // (This requires mapping piece IDs to board squares)
}
```

### Current Blocker
We still need to figure out the **Piece ID → Square mapping**.

The board doesn't tell us "piece 7 is on square h1" - we have to:
- Track it from the starting position
- Update when pieces move

This is complex but doable.

## Recommendation
For a **working demo TODAY**, I suggest:
1. Use manual FEN input (you type the position)
2. Display it beautifully on the projection screen
3. Add PGN move list sidebar
4. Skip automatic sync until we decode the piece ID mapping

This gives you a usable broadcast tool immediately.

---
*Updated: January 26, 2026 11:51 AM*
