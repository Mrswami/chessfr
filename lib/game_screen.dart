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
  bool _isRotated = false;

  @override
  Widget build(BuildContext context) {
    List<String?> board = _parseFen(widget.fen);
    if (_isRotated) {
      board = board.reversed.toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Ultra dark for TV
      body: Stack(
        children: [
          // THE BIG BOARD
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white12, width: 2),
                  ),
                  child: Column(
                      children: List.generate(8, (rank) {
                        return Expanded(
                          child: Row(
                            children: List.generate(8, (file) {
                              bool isDark = (rank + file) % 2 == 1;
                              Color squareColor = isDark 
                                  ? const Color(0xFF556B2F) // Olive Dark
                                  : const Color(0xFFF0E68C); // Khaki Light
                              
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
                  label: "Dashboard", 
                  onPressed: widget.onBack
                ),
                Text(
                  "CHESSUP PRO PROJECTOR",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    letterSpacing: 6,
                    fontSize: 14,
                    fontWeight: FontWeight.bold
                  ),
                ),
                Row(
                  children: [
                    _HeaderBtn(
                      icon: Icons.rotate_right, 
                      label: "Flip", 
                      onPressed: () => setState(() => _isRotated = !_isRotated),
                    ),
                    const SizedBox(width: 8),
                    _HeaderBtn(
                      icon: Icons.terminal, 
                      label: "Logs", 
                      onPressed: () => setState(() => _showDebug = !_showDebug),
                      isActive: _showDebug,
                    ),
                  ],
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
                    "PICKUP: ${widget.liftedSquare}",
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
                    const Divider(),
                    const Text("CURRENT POSITION:", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10)),
                    const SizedBox(height: 4),
                    SelectableText(
                      widget.fen, 
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')
                    ),
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
    
    String symbol = "";
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
        fontSize: 28, // Much smaller for proper fit
        color: isWhite ? Colors.white : const Color(0xFF151515), // charcoal
        shadows: [
          Shadow(
            offset: const Offset(0, 0), 
            blurRadius: 4, 
            color: isWhite ? Colors.black45 : Colors.white60
          ),
          if (isWhite) const Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black45)
        ],
      ),
    );
  }

  List<String?> _parseFen(String fen) {
    List<String?> board = List.filled(64, null);
    String placement = fen.split(' ')[0];
    
    // FEN is top-down: rank 8 (index 56-63) down to rank 1 (index 0-7)
    int rank = 7;  // Start at rank 7 (top)
    int file = 0;
    
    for (int i = 0; i < placement.length; i++) {
        String char = placement[i];
        if (char == '/') {
          rank--;  // Move down one rank
          file = 0;
        } else {
            int? skip = int.tryParse(char);
            if (skip != null) {
              file += skip;
            } else {
              if (rank >= 0 && rank < 8 && file >= 0 && file < 8) {
                board[rank * 8 + file] = char;
              }
              file++;
            }
        }
    }
    return board;
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
