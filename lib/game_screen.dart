import 'package:flutter/material.dart';

class GameProjectionScreen extends StatelessWidget {
  final String fen;
  final List<String> lastLogs;
  final String? liftedSquare;
  final VoidCallback onDisconnect;
  final VoidCallback? onBack;

  const GameProjectionScreen({
    super.key, 
    required this.fen, 
    required this.lastLogs,
    this.liftedSquare,
    required this.onDisconnect,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Parse FEN to a 64-item list
    List<String?> board = _parseFen(fen);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a), // Dark background for TV projection
      appBar: AppBar(
        title: const Text("ChessUp Broadcast"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: onBack != null ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ) : null,
        actions: [
          IconButton(icon: const Icon(Icons.cast), onPressed: () {}), // Fake Cast Button for UI
          IconButton(icon: const Icon(Icons.exit_to_app), onPressed: onDisconnect),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Debug Info (Smaller on mobile, visible for TV)
          Container(
            width: 250,
            color: Colors.black45,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("LIVE STATUS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                const SizedBox(height: 8),
                Text("Lifted: ${liftedSquare ?? 'None'}", style: const TextStyle(color: Colors.cyanAccent)),
                const Divider(color: Colors.white24),
                const Text("RECENT TRAFFIC", style: TextStyle(fontSize: 10, color: Colors.grey)),
                Expanded(
                  child: ListView.builder(
                    itemCount: lastLogs.length,
                    itemBuilder: (context, index) => Text(
                      lastLogs[index], 
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.greenAccent)
                    ),
                  ),
                ),
                const Divider(),
                Text("FEN: $fen", style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          
          // Right Side: The Board
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12, width: 4),
                    boxShadow: [
                       BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                    ],
                  ),
                  child: Column(
                    children: List.generate(8, (rank) {
                      return Expanded(
                        child: Row(
                          children: List.generate(8, (file) {
                            // Calculate Square Color
                            bool isDark = (rank + file) % 2 == 1;
                            Color squareColor = isDark ? const Color(0xFF769656) : const Color(0xFFeeeed2); // Classic Green/White
                            
                            // Get Piece
                            // FEN Ranks are 8->1 (Top to Bottom), so index matches standard reading direction
                            int index = (rank * 8) + file;
                            String? piece = (index < board.length) ? board[index] : null;

                            return Expanded(
                              child: Container(
                                color: squareColor,
                                child: Center(
                                  child: _buildPiece(piece),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildPiece(String? pieceCode) {
    if (pieceCode == null || pieceCode.isEmpty) return null;
    
    // Simple Unicode for now. We can swap for SVG Assets for "Premium" look later.
    String symbol = "";
    Color color = Colors.black;
    
    switch (pieceCode) {
      case 'K': symbol = "♔"; color = Colors.white; break;
      case 'Q': symbol = "♕"; color = Colors.white; break;
      case 'R': symbol = "♖"; color = Colors.white; break;
      case 'B': symbol = "♗"; color = Colors.white; break;
      case 'N': symbol = "♘"; color = Colors.white; break;
      case 'P': symbol = "♙"; color = Colors.white; break;
      
      case 'k': symbol = "♚"; color = Colors.black; break;
      case 'q': symbol = "♛"; color = Colors.black; break;
      case 'r': symbol = "♜"; color = Colors.black; break;
      case 'b': symbol = "♝"; color = Colors.black; break;
      case 'n': symbol = "♞"; color = Colors.black; break;
      case 'p': symbol = "♟"; color = Colors.black; break;
    }

    return Text(
      symbol,
      style: TextStyle(
        fontSize: 32, 
        color: color,
        shadows: [
           // Outline for visibility
           if (color == Colors.white) const Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black54),
        ]
      ),
    );
  }

  // Quick FEN parser
  List<String?> _parseFen(String fen) {
    List<String?> squares = List.filled(64, null);
    String placement = fen.split(' ')[0]; // Get just the piece placement part
    
    int rank = 0;
    int file = 0;
    
    for (int i = 0; i < placement.length; i++) {
        String char = placement[i];
        if (char == '/') {
            rank++;
            file = 0;
        } else {
            int? skip = int.tryParse(char);
            if (skip != null) {
                file += skip;
            } else {
                if (rank < 8 && file < 8) {
                    squares[rank * 8 + file] = char;
                }
                file++;
            }
        }
    }
    return squares;
  }
}
