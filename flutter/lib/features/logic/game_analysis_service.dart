import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/foundation.dart';
import 'stockfish_service.dart';

class GameAnalysisService {
  final StockfishService _stockfish;

  GameAnalysisService(this._stockfish);

  /// Analyzes a PGN string and finds "Swing Spots".
  /// Returns a list of [SwingSpot]s.
  Future<List<SwingSpot>> findSwingSpots(String pgn, {String? userSide}) async {
    final game = chess_lib.Chess();
    game.load_pgn(pgn);
    
    // Determine user side if not provided. 
    // We can guess from PGN headers if available, or assume White/User provided.
    // simpler: pass userSide 'w' or 'b' or username.
    // For now, let's analyze ALL swings and filter by who made the bad move.

    // Replay the game move by move and analyze
    final moves = game.history(options: {'verbose': true});
    final spots = <SwingSpot>[];
    
    // Create a fresh board to replay
    final replayBoard = chess_lib.Chess();
    // Assuming standard start (can support fen setups later)

    double? previousEval; // + is White, - is Black
    
    for (int i = 0; i < moves.length; i++) {
      final move = moves[i];
      final fenBefore = replayBoard.fen;
      
      // We analyze the position BEFORE the move to see what was expected
      // BUT to detect a blunder, we usually compare:
      // Eval(Position Before) vs Eval(Position After) ? 
      // No, that measures how much the board changed.
      // Better: 
      // 1. Analyze Position Before -> Best Move Eval (Expected)
      // 2. Analyze Position After (from opponent perspective) -> Current Eval (Actual)
      // The difference is the error.
      
      // Optimization: We only need to analyze "Position After" if we want to know
      // strictly how bad the move was.
      // Swing = Eval(Before) - Eval(After_Corrected_For_Turn).
      
      // Let's keep it simple for MVP:
      // Analyze Position Before. Get Top Move Eval.
      // Analyze Position After. Get Top Move Eval.
      // Compare.
      // Note: Eval is always from side-to-move perspective in Engine,
      // OR absolute (White positive). Stockfish usually gives centipawns relative to side to move
      // but commonly normalized to White. Let's assume standard UCI (cp is relative to side moving).
      // Actually my StockfishService returns raw CP.
      
      // For speed, let's analyze only every few moves or deep analyze on demand.
      // But user wants "Swing Spots".
      // Let's mock the "deep search" with the engine service we built.
      
      // To run this reasonably fast on a phone, we use lower depth (e.g. 10-12).
      
      final bestMovesBefore = await _stockfish.getTopMoves(fenBefore, depth: 10);
      if (bestMovesBefore.isEmpty) {
        replayBoard.move(move);
        continue;
      }
      
      final bestEvalBefore = bestMovesBefore.first.evaluation; // Relative to side to move
      
      replayBoard.move(move);
      final fenAfter = replayBoard.fen;
      
      // To see if the move was bad, we check the eval of the NEW position.
      // The new position is opponent to move.
      // So if I am White, and I play bad, position after is Black to move.
      // Black's eval should be HIGH (good for black).
      // White's eval (previous) was HIGH (good for White).
      // So Eval(Before, White) = +100.
      // Eval(After, Black) = +100 (Black is winning? No).
      
      // Let's normalize everything to White's perspective for comparison.
      // If side was White: WhiteEval = ReportEval.
      // If side was Black: WhiteEval = -ReportEval.
      
      final sideMoving = replayBoard.turn == chess_lib.Color.WHITE ? 'b' : 'w'; // Wait, after move, turn flipps.
      // Before move i:
      // If i=0 (Move 1), turn is White.
      // After replayBoard.move(move), turn is Black.
      
      final turnBefore = i % 2 == 0 ? 'w' : 'b'; 
      // (Standard game starting white)
      
      double evalBeforeWhite = turnBefore == 'w' ? bestEvalBefore.toDouble() : -bestEvalBefore.toDouble();
      
      // Now we have the Eval After. We can re-analyze OR just use the previous calculation 
      // from the next iteration?
      // Actually, accurate blunder check needs analysis of the move played.
      // Stockfish "searchmoves" option can score specific moves.
      // OR we just analyze the board after.
      
      final bestMovesAfter = await _stockfish.getTopMoves(fenAfter, depth: 10);
       if (bestMovesAfter.isEmpty) continue;
       
      final bestEvalAfter = bestMovesAfter.first.evaluation; // Relative to side to move (Opponent)
      
      // Perspective of side who JUST moved.
      // If White just moved. Now Black to move.
      // Eval is for Black. 
      // WhiteEval = -Eval(Black).
      
      double evalAfterWhite = turnBefore == 'w' ? -bestEvalAfter.toDouble() : bestEvalAfter.toDouble();
      
      // Swing calculation (Positive = White Improved, Negative = White Worsened)
      double swing = evalAfterWhite - evalBeforeWhite;
      
      // If turn was White, we want Swing to be roughly 0. 
      // If Swing is huge negative -> White Blundered.
      // If turn was Black, we want Swing to be roughly 0.
      // If Swing is huge positive -> Black Blundered.
      
      bool isBlunder = false;
      if (turnBefore == 'w' && swing < -100) isBlunder = true; // Lost 1 pawn or more
      if (turnBefore == 'b' && swing > 100) isBlunder = true; // Gained 1 pawn (for White) -> Black lost 1 pawn
      
      // Filter by user side if specified
      if (isBlunder && (userSide == null || userSide == turnBefore)) {
         spots.add(SwingSpot(
           moveIndex: i,
           fenBefore: fenBefore,
           movePlayedSan: move['san'],
           evalBefore: evalBeforeWhite,
           evalAfter: evalAfterWhite,
           swing: swing,
         ));
      }
    }
    
    return spots;
  }
}

class SwingSpot {
  final int moveIndex;
  final String fenBefore;
  final String movePlayedSan;
  final double evalBefore; // Normalized to White cp
  final double evalAfter;  // Normalized to White cp
  final double swing;
  
  SwingSpot({
    required this.moveIndex,
    required this.fenBefore,
    required this.movePlayedSan,
    required this.evalBefore,
    required this.evalAfter,
    required this.swing,
  });
}
