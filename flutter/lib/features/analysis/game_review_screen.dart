import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;

class GameReviewScreen extends StatefulWidget {
  final String pgn;
  final String? initialFen;

  const GameReviewScreen({
    super.key,
    required this.pgn,
    this.initialFen,
  });

  @override
  State<GameReviewScreen> createState() => _GameReviewScreenState();
}

class _GameReviewScreenState extends State<GameReviewScreen> {
  late ChessBoardController _controller;
  // No manual move parsing for MVP, relying on controller's board state and PGN string display.

  @override
  void initState() {
    super.initState();
    _controller = ChessBoardController();
    
    // Load the game
    if (widget.initialFen != null) {
      _controller.loadFen(widget.initialFen!);
    }
    
    // Load PGN if available. 
    if (widget.pgn.isNotEmpty) {
      try {
        _controller.loadPGN(widget.pgn);
      } catch (e) {
        debugPrint("Error loading PGN: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Game Review"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () {
               // Initial version might not support flip easily without recreating controller 
               // or if the widget supports it. usually BoardOrientation.
            },
            tooltip: "Flip Board",
          ),
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ghost Analysis Mode coming soon!")),
              );
            },
            tooltip: "Analyze Position (Ghost Mode)",
          ),
        ],
      ),
      body: Column(
        children: [
          // Board Area
          Expanded(
            flex: 3,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ChessBoard(
                  controller: _controller,
                  boardColor: BoardColor.brown, // Or customize for "Dark Digital" theme
                  boardOrientation: PlayerColor.white,
                  enableUserMoves: false, // Review mode only
                ),
              ),
            ),
          ),

          // Controls & Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.white.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page, size: 32),
                  color: Colors.cyanAccent,
                  onPressed: () {
                    _controller.resetBoard(); // Goes to start? Or loadFen(start)
                    // Need to verify library behavior for "Go to Start"
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 32),
                  color: Colors.cyanAccent,
                  onPressed: () {
                    _controller.undoMove();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 32),
                  color: Colors.cyanAccent,
                  onPressed: () {
                    // navigate forward logic 
                    // flutter_chess_board might not have strict "redo" if strictly PGN based
                    // We might need to maintain the move list and apply moves manually.
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.last_page, size: 32),
                  color: Colors.cyanAccent,
                  onPressed: () {
                    // Re-load full PGN
                    if (widget.pgn.isNotEmpty) _controller.loadPGN(widget.pgn);
                  },
                ),
              ],
            ),
          ),

          // Move List / Stats Area
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1A1A1A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "MOVE HISTORY", 
                    style: TextStyle(
                      color: Colors.white54, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.2
                    )
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.pgn.isEmpty ? "No moves recorded." : widget.pgn,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
