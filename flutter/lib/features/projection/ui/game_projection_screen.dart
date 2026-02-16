import 'package:flutter/material.dart';
import '../services/chessup_board_service.dart';

class GameProjectionScreen extends StatefulWidget {
  final String fen;
  final List<LogEntry> logs;
  final int? liftedSquare;
  final VoidCallback onDisconnect;
  final VoidCallback? onBack;

  const GameProjectionScreen({
    super.key, 
    required this.fen, 
    required this.logs,
    this.liftedSquare,
    required this.onDisconnect,
    this.onBack,
  });

  @override
  State<GameProjectionScreen> createState() => _GameProjectionScreenState();
}

class _GameProjectionScreenState extends State<GameProjectionScreen> {
  bool _showDebug = false;
  bool _isFlipped = false;

  @override
  Widget build(BuildContext context) {
    final displayFen = (widget.fen == "No Board Data" || widget.fen.isEmpty) 
        ? "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" 
        : widget.fen;
    
    final board = _fenToBoard(displayFen);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(displayFen),

            // Board Area
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: _buildBoard(board),
                  ),

                  // Lifted Square HUD
                  if (widget.liftedSquare != null)
                    _buildTouchOverlay(),

                  // Debug Console
                  if (_showDebug)
                    _buildDebugOverlay(displayFen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String fen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black45,
        border: Border(bottom: BorderSide(color: Colors.cyan.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.cyanAccent),
            onPressed: widget.onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("OPTICAL LINK ACTIVE", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2)),
                Text(
                  _getTurnLabel(fen),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          _ActionButton(
            icon: Icons.flip,
            active: _isFlipped,
            onTap: () => setState(() => _isFlipped = !_isFlipped),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.data_object,
            active: _showDebug,
            onTap: () => setState(() => _showDebug = !_showDebug),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            onPressed: widget.onDisconnect,
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(List<String?> board) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 2),
        boxShadow: [
           BoxShadow(color: Colors.cyan.withOpacity(0.1), blurRadius: 20),
        ],
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
                  int hwSq = rank * 8 + file;
                  bool isHighlighted = widget.liftedSquare == hwSq;
                  
                  bool isDark = (rank + file) % 2 == 0;
                  Color baseColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFF2A2A2A);
                  
                  int boardIdx = (rank * 8) + file;
                  String? piece = (boardIdx < board.length) ? board[boardIdx] : null;

                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isHighlighted ? Colors.cyan.withOpacity(0.4) : baseColor,
                        border: isHighlighted ? Border.all(color: Colors.cyanAccent, width: 2) : null,
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
    );
  }

  Widget _buildTouchOverlay() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.cyan.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               Icon(Icons.touch_app, color: Colors.white, size: 18),
               SizedBox(width: 8),
               Text("PIECE LIFTED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugOverlay(String fen) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        color: Colors.black.withOpacity(0.9),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("HARDWARE DATA STREAM", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                itemCount: widget.logs.length,
                itemBuilder: (ctx, i) {
                   final log = widget.logs[i];
                   return Padding(
                     padding: const EdgeInsets.symmetric(vertical: 2),
                     child: Text(
                       "[${log.timestamp.second}s] ${log.text}",
                       style: TextStyle(
                          color: _getLogColor(log.type), 
                          fontSize: 11, 
                          fontFamily: 'monospace'
                       ),
                     ),
                   );
                },
              ),
            ),
            const Divider(color: Colors.white24),
            const Text("FEN POSITION", style: TextStyle(color: Colors.grey, fontSize: 10)),
            Text(fen, style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.error: return Colors.redAccent;
      case LogType.success: return Colors.greenAccent;
      case LogType.tx: return Colors.blueAccent;
      case LogType.rx: return Colors.orangeAccent;
      default: return Colors.white60;
    }
  }

  String _getTurnLabel(String fen) {
    if (fen == "No Board Data" || fen.isEmpty) return "Board Disconnected";
    List<String> parts = fen.split(' ');
    bool isBlack = parts.length > 1 && parts[1] == 'b';
    return isBlack ? "Black to Move" : "White to Move";
  }

  Widget _buildPiece(String? pieceCode) {
    if (pieceCode == null || pieceCode.isEmpty || pieceCode == '?') return const SizedBox.shrink();
    
    String symbol = "";
    bool isWhite = pieceCode == pieceCode.toUpperCase();
    
    switch (pieceCode.toUpperCase()) {
      case 'K': symbol = "♚"; break;
      case 'Q': symbol = "♛"; break;
      case 'R': symbol = "♜"; break;
      case 'B': symbol = "♝"; break;
      case 'N': symbol = "♞"; break;
      case 'P': symbol = "♟"; break;
      default: return const SizedBox.shrink();
    }

    return Text(
      symbol,
      style: TextStyle(
        fontSize: 36,
        color: isWhite ? Colors.white : Colors.black,
        shadows: isWhite 
            ? [const Shadow(color: Colors.cyanAccent, blurRadius: 4)] 
            : [const Shadow(color: Colors.white10, blurRadius: 2)],
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: active ? Colors.cyanAccent : Colors.white24, size: 20),
      onPressed: onTap,
    );
  }
}
