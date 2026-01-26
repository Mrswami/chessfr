
// FEN Mapping for ChessUp Board
// We know pieces are represented by byte values. 
// Standard conventions (and V1 protocol) often use:
// 0x00 = Empty
// 0x01 = White Pawn, 0x02 = White Knight, etc.
// 0x81 = Black Pawn, etc. (High bit set for Black)

class ChessProtocol {
  
  static String parseBoardState(List<int> packet) {
    // The packet usually contains (Header 2 bytes) + (Grid data)
    // For a 12-wide grid, 8 ranks = 96 bytes of data. 
    // If the packet is smaller, we'll fall back.
    int stride = (packet.length >= 98) ? 12 : 8;

    StringBuffer fen = StringBuffer();
    // Loop Ranks (7 down to 0) - FEN is top-down (Black to White)
    for (int rank = 7; rank >= 0; rank--) {
      int emptyCount = 0;
      for (int file = 0; file < 8; file++) {
        int index = 2 + (rank * stride) + file;
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
          
          // Black (Commonly using bit 7 or secondary IDs)
          case 0x81: case 0x11: case 0x09: return "p";
          case 0x82: case 0x12: case 0x0A: return "n";
          case 0x83: case 0x13: case 0x0B: return "b";
          case 0x84: case 0x14: case 0x0C: return "r";
          case 0x85: case 0x15: case 0x0D: return "q";
          case 0x86: case 0x16: case 0x0E: return "k";
          
          default: return b > 0 ? "?" : ""; // Show unknown pieces as ?, blank as empty
      }
  }
}
