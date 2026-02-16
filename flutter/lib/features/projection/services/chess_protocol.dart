// FEN Mapping for ChessUp Board
// We know pieces are represented by byte values. 
// Standard conventions (and V1 protocol) often use:
// 0x00 = Empty
// 0x01 = White Pawn, 0x02 = White Knight, etc.
// 0x81 = Black Pawn, etc. (High bit set for Black)

class ChessProtocol {
  
  static String parseBoardState(List<int> packet) {
    if (packet.length < 71) return ""; // Minimum size

    // Full packet (73 bytes) structure:
    // [0] Header (0x67)
    // [1-64] Board Squares
    // [65] Turn (0=w, 1=b)
    // [66-69] Castling (K, Q, k, q)
    // [70] En Passant Square Index
    // [71] Halfmove clock
    // [72] Fullmove counter

    StringBuffer fen = StringBuffer();
    // 1. Piece Placement (Ranks 8 to 1)
    for (int rank = 7; rank >= 0; rank--) {
      int emptyCount = 0;
      for (int file = 0; file < 8; file++) {
        // Physical index: hardware uses index 1-64 for squares
        // Mapping depends on how the board stores it. 
        // Based on APK, it seems to be rank-major.
        int index = 1 + (rank * 8) + file; 
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

    // 2. Active Color
    String turn = "w";
    if (packet.length > 65) {
        turn = (packet[65] == 0) ? "w" : "b";
    }
    fen.write(" $turn");

    // 3. Castling Availability
    String castling = "";
    if (packet.length > 69) {
        if (packet[66] == 1) castling += "K";
        if (packet[67] == 1) castling += "Q";
        if (packet[68] == 1) castling += "k";
        if (packet[69] == 1) castling += "q";
    }
    fen.write(" ${castling.isEmpty ? "-" : castling}");

    // 4. En Passant Square
    String ep = "-";
    if (packet.length > 70 && packet[70] != 64) {
        int idx = packet[70];
        int r = idx ~/ 8;
        int f = idx % 8;
        ep = "${String.fromCharCode('a'.codeUnitAt(0) + f)}${r + 1}";
    }
    fen.write(" $ep");

    // 5. Halfmove Clock & Fullmove Number
    int half = (packet.length > 71) ? packet[71] : 0;
    int full = (packet.length > 72) ? packet[72] : 1;
    fen.write(" $half $full");
    
    return fen.toString();
  }

  static String _byteToPiece(int b) {
      // Official Mapping Decoded from ChessUp APK boardStateArray:
      switch(b) {
          case 0x40: return ""; // Empty Square
          
          // White Pieces
          case 0x00: return "P"; // White Pawn
          case 0x01: return "R"; // White Rook
          case 0x02: return "N"; // White Knight
          case 0x03: return "B"; // White Bishop
          case 0x04: return "Q"; // White Queen
          case 0x05: return "K"; // White King
          
          // Black Pieces 
          case 0x08: return "p"; // Black Pawn
          case 0x09: return "r"; // Black Rook
          case 0x0a: return "n"; // Black Knight
          case 0x0b: return "b"; // Black Bishop
          case 0x0c: return "q"; // Black Queen
          case 0x0d: return "k"; // Black King
          
          default: return b > 0 ? "?" : ""; // Unknown
      }
  }
}
