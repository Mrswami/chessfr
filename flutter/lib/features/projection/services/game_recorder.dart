import 'package:chess/chess.dart' as chess_lib;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class GameRecorder {
  chess_lib.Chess _game = chess_lib.Chess();
  final List<String> _moveHistory = [];
  bool _isRecording = false;
  String? _liveSessionId;

  bool _isGhostMode = false;

  bool get isRecording => _isRecording;
  bool get isGhostMode => _isGhostMode;

  set isGhostMode(bool value) {
    _isGhostMode = value;
    debugPrint("👻 Ghost Mode set to: $value");
  }

  // Supabase client
  final _client = Supabase.instance.client;

  void startNewGame() {
    _game = chess_lib.Chess();
    _moveHistory.clear();
    _isRecording = true;
    
    if (!_isGhostMode) {
      _createLiveSession(); // Start a new session in DB
    } else {
      debugPrint("👻 Ghost Game Started (No DB)");
    }
  }

  void stopRecording() {
    _isRecording = false;
    if (!_isGhostMode) {
      _finalizeLiveSession();
    } else {
      debugPrint("👻 Ghost Game Ended (No DB)");
    }
  }

  // Tries to infer the move that happened between the internal state and the new FEN
  void handleNewFen(String newFen) {
    if (!_isRecording) {
         // Auto-start logic if needed
         if (_simplifyFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") != _simplifyFen(newFen)) {
             debugPrint("🚀 AUTO-STARTING GAME RECORDING!");
             startNewGame();
         } else {
             return;
         }
    }
    
    // 1. Check if FEN is just the same (no move)
    if (_simplifyFen(_game.fen) == _simplifyFen(newFen)) return;

    // 2. Try to find a legal move that leads to this FEN
    // This is computationally expensive if we check ALL moves every frame.
    // Optimization: Only check if board state changed.
    
    final moves = _game.moves();
    bool found = false;
    
    for (final move in moves) {
      // Create a temporary game to test the move
      final tempGame = chess_lib.Chess.fromFEN(_game.fen);
      tempGame.move(move);
      
      if (_simplifyFen(tempGame.fen) == _simplifyFen(newFen)) {
        found = true;
        _game.move(move);
        _moveHistory.add(_game.pgn().split(" ").last); // Store rudimentary move string
        debugPrint("✅ Recorded Move: ${_moveHistory.last}");
        
        // Broadcast update
        if (!_isGhostMode) {
          _updateLiveSession();
        }

        // Check End Conditions
        if (_game.in_checkmate) {
           stopRecording();
        } else if (_game.in_draw) {
           stopRecording();
        }
        break;
      }
    }

    if (!found) {
       debugPrint("⚠️ Move Logic Out of Sync! Resyncing internal engine to board.");
       // Force sync internal engine to board FEN to recover
       _game = chess_lib.Chess.fromFEN(newFen);
    }
  }

  // Helper to compare FENs ignoring halfmove/fullmove clocks
  String _simplifyFen(String fullFen) {
    final parts = fullFen.split(" ");
    if (parts.length >= 4) {
      return "${parts[0]} ${parts[1]} ${parts[2]} ${parts[3]}"; 
    }
    return fullFen;
  }
  
  // --- Supabase Integration ---

  Future<void> _createLiveSession() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // TODO: Create a 'training_sessions' or 'live_games' table in Supabase
      // For now, we simulate success
      final response = await _client.from('live_sessions').insert({
        'user_id': user.id,
        'status': 'active',
        'started_at': DateTime.now().toIso8601String(),
        'fen': _game.fen,
      }).select().single();
      _liveSessionId = response['id'];
      debugPrint("✅ Live session started: $_liveSessionId");
    } catch (e) {
      debugPrint("Error creating live session: $e");
    }
  }

  Future<void> _updateLiveSession() async {
    if (_liveSessionId == null) return;
    try {
      await _client.from('live_sessions').update({
        'fen': _game.fen,
        'pgn': _game.pgn(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _liveSessionId!);
    } catch (e) {
      debugPrint("Error updating live session: $e");
    }
  }

  Future<void> _finalizeLiveSession() async {
    if (_liveSessionId == null) return;
    try {
      await _client.from('live_sessions').update({
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _liveSessionId!);
      debugPrint("🏁 Live session finalized: $_liveSessionId");
    } catch (e) {
      debugPrint("Error finalizing session: $e");
    }
  }
}
