import 'package:flutter/material.dart';

class GameProjectionScreen extends StatefulWidget {
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
  State<GameProjectionScreen> createState() => _GameProjectionScreenState();
}

class _GameProjectionScreenState extends State<GameProjectionScreen> {
  bool _showDebug = false;

  @override
  Widget build(BuildContext context) {
    List<String?> board = _parseFen(widget.fen);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Ultra dark for TV
      body: Stack(
        children: [
          // THE BIG BOARD
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Column(
                      children: List.generate(8, (rank) {
                        return Expanded(
                          child: Row(
                            children: List.generate(8, (file) {
                              bool isDark = (rank + file) % 2 == 1;
                              Color squareColor = isDark 
                                  ? const Color(0xFF4B7399) // Premium Blue-Grey
                                  : const Color(0xFFEAE9D2); // Premium Cream
                              
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
          ),

          // OVERLAY UI - TOP BAR
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderBtn(
                  icon: Icons.arrow_back, 
                  label: "Studio", 
                  onPressed: widget.onBack
                ),
                Text(
                  "CHESSUP LIVE CAST",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 4,
                    fontSize: 12,
                    fontWeight: FontWeight.bold
                  ),
                ),
                _HeaderBtn(
                  icon: Icons.bug_report, 
                  label: "Logs", 
                  onPressed: () => setState(() => _showDebug = !_showDebug),
                  isActive: _showDebug,
                ),
              ],
            ),
          ),

          // LIFTED SQUARE INDICATOR (Top center)
          if (widget.liftedSquare != null)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "PIECE LIFTED: ${widget.liftedSquare}",
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

          // DEBUG SIDEBAR (Optional)
          if (_showDebug)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 300,
                color: Colors.black.withOpacity(0.9),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    const Text("RAW TRAFFIC", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.white24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.lastLogs.length,
                        itemBuilder: (ctx, i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            widget.lastLogs[i],
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ),
                    Text("FEN: ${widget.fen}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPiece(String? pieceCode) {
    if (pieceCode == null || pieceCode.isEmpty) return const SizedBox.shrink();
    
    // Using high-res Unicode or we could use SVG assets here
    String symbol = "";
    Color color = Colors.black;
    bool isWhite = pieceCode == pieceCode.toUpperCase();
    
    switch (pieceCode.toUpperCase()) {
      case 'K': symbol = isWhite ? "♔" : "♚"; break;
      case 'Q': symbol = isWhite ? "♕" : "♛"; break;
      case 'R': symbol = isWhite ? "♖" : "♜"; break;
      case 'B': symbol = isWhite ? "♗" : "♝"; break;
      case 'N': symbol = isWhite ? "♘" : "♞"; break;
      case 'P': symbol = isWhite ? "♙" : "♟"; break;
    }

    return Text(
      symbol,
      style: TextStyle(
        fontSize: 48, 
        color: isWhite ? Colors.white : Colors.black,
        shadows: isWhite ? [
          const Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black45)
        ] : [],
      ),
    );
  }

  List<String?> _parseFen(String fen) {
    List<String?> squares = List.filled(64, null);
    String placement = fen.split(' ')[0];
    int rank = 0, file = 0;
    for (int i = 0; i < placement.length; i++) {
        String char = placement[i];
        if (char == '/') { rank++; file = 0; }
        else {
            int? skip = int.tryParse(char);
            if (skip != null) { file += skip; }
            else { if (rank < 8 && file < 8) squares[rank * 8 + file] = char; file++; }
        }
    }
    return squares;
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isActive;

  const _HeaderBtn({required this.icon, required this.label, this.onPressed, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.amber : Colors.white12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.black : Colors.white),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
