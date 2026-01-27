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
  bool _isFlipped = false; // Default: White at bottom (Rank 1)

  @override
  Widget build(BuildContext context) {
    // Standard starting FEN if empty
    final displayFen = (widget.fen == "No Board Data" || widget.fen.isEmpty) 
        ? "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" 
        : widget.fen;
    
    final board = _fenToBoard(displayFen);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // --- NEATER TOP BAR ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: const Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white54),
                    onPressed: widget.onBack,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("CHESSPUP PRO", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
                        Text(
                          _getTurnLabel(displayFen),
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Controls
                  _IconToggle(
                    icon: Icons.flip,
                    active: _isFlipped,
                    activeColor: Colors.orange,
                    onTap: () => setState(() => _isFlipped = !_isFlipped),
                  ),
                  const SizedBox(width: 8),
                  _IconToggle(
                    icon: Icons.terminal_rounded,
                    active: _showDebug,
                    activeColor: Colors.greenAccent,
                    onTap: () => setState(() => _showDebug = !_showDebug),
                  ),
                  const SizedBox(width: 12),
                  // Status Indicators
                  _statusDot(widget.fen != "No Board Data" && widget.fen.isNotEmpty, Colors.greenAccent),
                  const SizedBox(width: 6),
                  _statusDot(widget.liftedSquare != null, Colors.blueAccent),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 22),
                    onPressed: widget.onDisconnect,
                  ),
                ],
              ),
            ),

            // --- MAIN BOARD AREA ---
            Expanded(
              child: Stack(
                children: [
                  // THE CHESSBOARD
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Column(
                          children: List.generate(8, (rIdx) {
                            int rank = _isFlipped ? rIdx : (7 - rIdx);
                            return Expanded(
                              child: Row(
                                children: List.generate(8, (fIdx) {
                                  int file = _isFlipped ? (7 - fIdx) : fIdx;
                                  
                                  String coord = "${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}";
                                  bool isHighlighted = widget.liftedSquare == coord;
                                  
                                  bool isDark = (rank + file) % 2 == 0;
                                  Color baseColor = isDark ? const Color(0xFF4B533A) : const Color(0xFF818C6A);
                                  
                                  int boardIdx = (rank * 8) + file;
                                  String? piece = (boardIdx < board.length) ? board[boardIdx] : null;

                                  return Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isHighlighted ? Colors.blueAccent.withOpacity(0.9) : baseColor,
                                        border: isHighlighted ? Border.all(color: Colors.white, width: 2) : null,
                                      ),
                                      child: Center(child: _buildPiece(piece)),
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

                  // LIFTED SQUARE OVERLAY
                  if (widget.liftedSquare != null)
                    Positioned(
                      top: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10)],
                          ),
                          child: Text(
                            "TOUCH: ${widget.liftedSquare!.toUpperCase()}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ),

                  // LOG DRAWER OVERLAY
                  if (_showDebug)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.75,
                        color: Colors.black.withOpacity(0.95),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("HARDWARE LOGS", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                            const Divider(color: Colors.white24, height: 20),
                            Expanded(
                              child: ListView.builder(
                                itemCount: widget.lastLogs.length,
                                itemBuilder: (ctx, i) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    widget.lastLogs[i],
                                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                                  ),
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white24),
                            const Text("FEN POSITION:", style: TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            SelectableText(
                              displayFen,
                              style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusDot(bool active, Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : Colors.white10,
        boxShadow: active ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)] : null,
      ),
    );
  }

  String _getTurnLabel(String fen) {
    if (fen == "No Board Data" || fen.isEmpty) return "Board Disconnected";
    List<String> parts = fen.split(' ');
    bool isBlack = parts.length > 1 && parts[1] == 'b';
    return isBlack ? "Black to move" : "White to move";
  }

  Widget _buildPiece(String? pieceCode) {
    if (pieceCode == null || pieceCode.isEmpty || pieceCode == '?') return const SizedBox.shrink();
    
    String symbol = "";
    bool isWhite = pieceCode == pieceCode.toUpperCase();
    
    switch (pieceCode.toUpperCase()) {
      case 'K': symbol = isWhite ? "♔" : "♚"; break;
      case 'Q': symbol = isWhite ? "♕" : "♛"; break;
      case 'R': symbol = isWhite ? "♖" : "♜"; break;
      case 'B': symbol = isWhite ? "♗" : "♝"; break;
      case 'N': symbol = isWhite ? "♘" : "♞"; break;
      case 'P': symbol = isWhite ? "♙" : "♟"; break;
      default: return const SizedBox.shrink();
    }

    return Text(
      symbol,
      style: TextStyle(
        fontSize: 34,
        color: isWhite ? Colors.white : Colors.black,
        shadows: isWhite ? [const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))] : [const Shadow(color: Colors.white38, blurRadius: 2)],
      ),
    );
  }

  List<String?> _fenToBoard(String fen) {
    List<String?> board = List.filled(64, null);
    try {
      String placement = fen.split(' ')[0];
      int rank = 7;
      int file = 0;
      for (int i = 0; i < placement.length; i++) {
        String c = placement[i];
        if (c == '/') {
          rank--;
          file = 0;
        } else {
          int? skip = int.tryParse(c);
          if (skip != null) {
            file += skip;
          } else if ('pnbrqkPNBRQK'.contains(c)) {
            if (rank >= 0 && rank < 8 && file >= 0 && file < 8) {
              board[rank * 8 + file] = c;
            }
            file++;
          }
        }
      }
    } catch (_) {}
    return board;
  }
}

class _IconToggle extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _IconToggle({required this.icon, required this.active, required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: active ? activeColor : Colors.white38, size: 20),
      ),
    );
  }
}
