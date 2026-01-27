import 'package:chess/chess.dart' as chess_lib;
import 'package:cloud_firestore/cloud_firestore.dart';

class GameRecorder {
  chess_lib.Chess _game = chess_lib.Chess();
  final List<String> _moveHistory = [];
  bool _isRecording = false;
  
  bool get isRecording => _isRecording;

  void startNewGame() {
    _game = chess_lib.Chess();
    _moveHistory.clear();
    _isRecording = true;
  }

  void stopRecording() {
    _isRecording = false;
  }

  // Tries to infer the move that happened between the internal state and the new FEN
  void handleNewFen(String newFen) {
    if (!_isRecording) return;
    
    // 1. Check if FEN is just the same (no move)
    if (_game.fen == newFen) return;

    // 2. Try to find a legal move that leads to this FEN
    final moves = _game.generate_moves();
    bool found = false;
    
    for (var move in moves) {
      _game.move(move);
      // Clean the FEN (remove move counts if needed for comparison)
      // Actually, ChessUp FEN might handle move counts differently to the library
      // So we compare broadly (Piece Placement + Active Color)
      if (_simplifyFen(_game.fen) == _simplifyFen(newFen)) {
        found = true;
        // move.san is not available on Move object in this version
        // We rely on _game.pgn() for the final output anyway
        _moveHistory.add(move.toString()); 
        print("✅ Recorded Move: $move");
        break; 
      }
      _game.undo(); // Backtrack
    }

    if (!found) {
      // Desync happened (or illegal move on board allowed)
      // We must force the state to accept the new reality
      print("⚠️ Desync: Could not find legal move to $newFen. Forcing state.");
      _game.load(newFen);
    }
  }

  // Helper to compare FENs ignoring halfmove/fullmove clocks which might mismatch
  String _simplifyFen(String fullFen) {
    final parts = fullFen.split(" ");
    if (parts.length >= 4) {
      // Join Board + Color + Castling + EnPassant
      return "${parts[0]} ${parts[1]} ${parts[2]} ${parts[3]}"; 
    }
    return fullFen;
  }

  Future<void> saveGameToFirebase(String result) async {
    if (_moveHistory.isEmpty) return;
    
    try {
      await FirebaseFirestore.instance.collection('games').add({
        'pgn': _game.pgn(),
        'fen': _game.fen,
        'moves': _moveHistory,
        'date': DateTime.now().toIso8601String(),
        'result': result, // "1-0", "0-1", "1/2-1/2"
      });
      print("☁️ Game Saved to Firebase!");
    } catch (e) {
      print("❌ Firebase Upload Error: $e");
    }
  }
}
