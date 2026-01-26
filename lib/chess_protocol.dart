
// FEN Mapping for ChessUp Board
// We know pieces are represented by byte values. 
// Standard conventions (and V1 protocol) often use:
// 0x00 = Empty
// 0x01 = White Pawn, 0x02 = White Knight, etc.
// 0x81 = Black Pawn, etc. (High bit set for Black)

class ChessProtocol {
  
  static String parseBoardState(List<int> packet) {
    if (packet.length < 66) return "Invalid Packet Size"; // Expecting Header + 64 Squares

    // Packet often starts with 71 XX ...
    // The board is 64 squares.
    
    // Let's assume the payload starts at index 2 (after 71 XX)
    // and runs for 64 bytes.
    
    StringBuffer fen = StringBuffer();
    // Loop Ranks (8 down to 1)
    for (int rank = 7; rank >= 0; rank--) {
      int emptyCount = 0;
      for (int file = 0; file < 8; file++) {
        int index = 2 + (rank * 8) + file;
        if (index >= packet.length) break;
        
        int pieceByte = packet[index];
        String piece = _byteToPiece(pieceByte);
        
        if (piece == "") {
            emptyCount++;
        } else {
            if (emptyCount > 0) {
                fen.write(emptyCount);
                emptyCount = 0;
            }
            fen.write(piece);
        }
      }
      if (emptyCount > 0) fen.write(emptyCount);
      if (rank > 0) fen.write("/");
    }
    
    return fen.toString();
  }

  static String _byteToPiece(int b) {
      // These are educated guesses based on common protocols.
      // We will refine this by looking at your logs!
      switch(b) {
          case 0x00: return "";
          // White
          case 0x01: return "P";
          case 0x02: return "N";
          case 0x03: return "B";
          case 0x04: return "R";
          case 0x05: return "Q";
          case 0x06: return "K";
          
          // Black (Assuming bit 7 or similar offset)
          // Often 0x81 or 0x09
          case 0x81: case 0x09: return "p";
          case 0x82: case 0x0A: return "n";
          case 0x83: case 0x0B: return "b";
          case 0x84: case 0x0C: return "r";
          case 0x85: case 0x0D: return "q";
          case 0x86: case 0x0E: return "k";
          
          default: return "?"; // Unknown piece ID
      }
  }
}
