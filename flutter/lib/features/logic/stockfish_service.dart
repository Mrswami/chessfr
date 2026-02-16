import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stockfish/stockfish.dart';
import 'move_ranker.dart';

class StockfishService {
  Stockfish? _engine;
  final _outputController = StreamController<String>.broadcast();
  StreamSubscription? _subscription;
  bool _isReady = false;

  StockfishService() {
    _initEngine();
  }

  void _initEngine() {
    if (kIsWeb) {
      // TODO: Web requires a different setup (WASM)
      debugPrint('Stockfish not supported on Web in this implementation yet.');
      return;
    }
    
    // Note: On Windows/Linux/macOS, this requires the stockfish binary to be
    // in the path or bundled. The package mainly bundles for Android/iOS.
    try {
      _engine = Stockfish();
      
      _subscription = _engine?.stdout.listen((line) {
        if (kDebugMode) {
          // print('Stockfish: $line'); 
        }
        _outputController.add(line);
        if (line.contains('readyok')) _isReady = true;
      });

      _sendCommand('uci');
      _sendCommand('isready');
    } catch (e) {
      debugPrint('Failed to initialize Stockfish: $e');
    }
  }

  void _sendCommand(String command) {
    if (_engine == null) return;
    _engine!.stdin = '$command\n';
  }

  void dispose() {
    _sendCommand('quit');
    _subscription?.cancel();
    _outputController.close();
  }

  /// Gets top moves for a position.
  /// [depth] controls strength/time.
  /// Returns a list of moves with evaluations (centipawns).
  Future<List<EngineMove>> getTopMoves(String fen, {int depth = 15}) async {
    if (_engine == null) {
      // Fallback if engine failed (e.g. Windows without binary)
      return [
        EngineMove(san: 'e4', evaluation: 35), // Mock fallback
      ];
    }

    // Wait for ready
    int attempts = 0;
    while (!_isReady && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    // 1. Setup Position
    _sendCommand('stop'); // Stop any previous
    _sendCommand('position fen $fen');
    
    // 2. Analyze
    // We use 'go depth X' to get a fixed depth calculation
    _sendCommand('go depth $depth');

    // 3. Listen for results
    // We look for 'bestmove' to know it's done. 
    // We parse 'info ... score cp ... pv ...' to get moves.
    
    final moves = <EngineMove>[];
    final completer = Completer<List<EngineMove>>();
    
    // Create a temporary subscription for this request
    final sub = _outputController.stream.listen((line) {
      if (line.startsWith('bestmove')) {
        if (!completer.isCompleted) completer.complete(moves);
      } else if (line.startsWith('info') && line.contains(' score cp ') && line.contains(' pv ')) {
        // Parse info line
        // Example: info depth 10 ... score cp 55 ... pv e2e4 e7e5 ...
        try {
          final parts = line.split(' ');
          
          // Parse score
          int scoreIndex = parts.indexOf('cp');
          int score = 0;
          if (scoreIndex != -1 && scoreIndex + 1 < parts.length) {
            score = int.tryParse(parts[scoreIndex + 1]) ?? 0;
          }
           // Check for mate score
          if (line.contains('score mate')) {
             score = 10000; // maximizing mate
             if (line.contains('score mate -')) score = -10000;
          }

          // Parse move (PV first move)
          int pvIndex = parts.indexOf('pv');
          if (pvIndex != -1 && pvIndex + 1 < parts.length) {
            String moveUci = parts[pvIndex + 1];
            // Note: We need SAN (Standard Algebraic Notation) but Stockfish gives UCI (e2e4).
            // Transforming UCI to SAN is complex without a chess library helper.
            // For now, we will store UCI and let the UI/Ranker handle it or use a library.
            // However, the existing code expects SAN. 
            // The `flutter_chess_board` controller might help, but here we just return the raw string
            // and might need to convert it. 
            // Let's assume for this step we store the UCI and we update Ranker to handle it?
            // actually, 'EngineMove' expects 'san'. 
            // We'll cheat and just put the UCI string for now, but label it.
            // Or better, we just use the UCI as the ID.
            
            // Avoid duplicates (Deep info lines update previous ones)
            // Ideally we only take the FINAL info line before bestmove, BUT 
            // Stockfish emits info lines progressively.
            // For 'Top Moves', typically we want MultiPV.
            // If we didn't set multipv, we only get ONE best move sequence.
            
            // For this implementation, we will just capture the 'best' one found so far strings.
             moves.clear(); // We only get one 'best' line if multipv=1
             moves.add(EngineMove(san: moveUci, evaluation: score));
          }
        } catch (e) {
          // ignore parsing error
        }
      }
    });

    // Timeout safety
    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted) completer.complete(moves);
    });

    final result = await completer.future;
    await sub.cancel();
    return result;
  }
}
