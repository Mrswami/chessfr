import 'package:chess/chess.dart' as chess_lib;
import 'stockfish_service.dart';

// ============================================
// MOVE CLASSIFICATION ENUM
// ============================================
enum MoveClassification {
  brilliant,   // ⭐ Only correct move in a complex position
  excellent,   // Near-best move, low CPL
  good,        // Solid, within acceptable range
  inaccuracy,  // CPL 50-100
  mistake,     // CPL 100-200
  blunder,     // CPL > 200
}

extension MoveClassificationExtension on MoveClassification {
  String get emoji {
    switch (this) {
      case MoveClassification.brilliant:  return '⭐';
      case MoveClassification.excellent:  return '✅';
      case MoveClassification.good:       return '👍';
      case MoveClassification.inaccuracy: return '❓';
      case MoveClassification.mistake:    return '❌';
      case MoveClassification.blunder:    return '💀';
    }
  }

  String get label {
    switch (this) {
      case MoveClassification.brilliant:  return 'Brilliant';
      case MoveClassification.excellent:  return 'Excellent';
      case MoveClassification.good:       return 'Good';
      case MoveClassification.inaccuracy: return 'Inaccuracy';
      case MoveClassification.mistake:    return 'Mistake';
      case MoveClassification.blunder:    return 'Blunder';
    }
  }

  String get name => toString().split('.').last;
}

// ============================================
// MOVE ANNOTATION
// ============================================
class MoveAnnotation {
  final int moveIndex;
  final String fen;
  final String san;
  final double evalBefore;       // White-normalized centipawns
  final double evalAfter;        // White-normalized centipawns
  final double cpl;              // Centipawn Loss (always positive)
  final MoveClassification classification;
  final double connectivityDelta;

  MoveAnnotation({
    required this.moveIndex,
    required this.fen,
    required this.san,
    required this.evalBefore,
    required this.evalAfter,
    required this.cpl,
    required this.classification,
    required this.connectivityDelta,
  });

  Map<String, dynamic> toJson() => {
    'moveIndex': moveIndex,
    'fen': fen,
    'san': san,
    'evalBefore': evalBefore,
    'evalAfter': evalAfter,
    'cpl': cpl,
    'classification': classification.name,
    'connectivityDelta': connectivityDelta,
  };
}

// ============================================
// GAME ANALYSIS SUMMARY
// ============================================
class GameAnalysisSummary {
  final String pgn;
  final String? userSide;
  final List<MoveAnnotation> annotatedMoves;

  GameAnalysisSummary({
    required this.pgn,
    this.userSide,
    required this.annotatedMoves,
  });

  int get brilliantCount => annotatedMoves.where((m) => m.classification == MoveClassification.brilliant).length;
  int get excellentCount => annotatedMoves.where((m) => m.classification == MoveClassification.excellent).length;
  int get goodCount => annotatedMoves.where((m) => m.classification == MoveClassification.good).length;
  int get inaccuracyCount => annotatedMoves.where((m) => m.classification == MoveClassification.inaccuracy).length;
  int get mistakeCount => annotatedMoves.where((m) => m.classification == MoveClassification.mistake).length;
  int get blunderCount => annotatedMoves.where((m) => m.classification == MoveClassification.blunder).length;

  List<MoveAnnotation> get brilliantMoves => annotatedMoves.where((m) => m.classification == MoveClassification.brilliant).toList();
  List<MoveAnnotation> get blunderMoves => annotatedMoves.where((m) => m.classification == MoveClassification.blunder).toList();

  // Converts to a format ready for Supabase insertion
  Map<String, dynamic> toSupabaseMap(String profileId, {
    String? chessComUrl,
    String? opponentUsername,
    int? opponentRating,
    String? timeControl,
    String? gameResult,
  }) =>
    {
      'profile_id': profileId,
      if (chessComUrl != null) 'chess_com_url': chessComUrl,
      'pgn': pgn,
      'user_side': userSide,
      if (opponentUsername != null) 'opponent_username': opponentUsername,
      if (opponentRating != null) 'opponent_rating': opponentRating,
      if (timeControl != null) 'time_control': timeControl,
      if (gameResult != null) 'game_result': gameResult,
      'total_moves': annotatedMoves.length,
      'brilliant_count': brilliantCount,
      'excellent_count': excellentCount,
      'good_count': goodCount,
      'inaccuracy_count': inaccuracyCount,
      'mistake_count': mistakeCount,
      'blunder_count': blunderCount,
      'annotated_moves': annotatedMoves.map((m) => m.toJson()).toList(),
      'brilliant_moves': brilliantMoves.map((m) => m.toJson()).toList(),
    };
}

// ============================================
// GAME ANALYSIS SERVICE
// ============================================
class GameAnalysisService {
  final StockfishService _stockfish;

  GameAnalysisService(this._stockfish);

  // -----------------------------------------------
  // BRILLIANT MOVE CLASSIFIER
  // A move is Brilliant when ALL are true:
  // 1. Position is complex: |evalBefore| < 300cp (not already decisive)
  // 2. The played move IS the engine's #1 choice
  // 3. Gap between top-1 and top-2 engine move >= 50cp
  // 4. CPL of the played move < 10cp (near-perfect)
  // -----------------------------------------------
  MoveClassification _classifyMove({
    required double evalBeforeWhite,
    required double evalAfterWhite,
    required double cpl,
    required List topMovesBefore,  // from Stockfish
    required String playedMoveUci, // e.g. "e2e4"
  }) {
    // Blunder / Mistake / Inaccuracy thresholds
    if (cpl >= 200) return MoveClassification.blunder;
    if (cpl >= 100) return MoveClassification.mistake;
    if (cpl >= 50) return MoveClassification.inaccuracy;

    // Check for Brilliant:
    // Condition 1: complex position
    final isComplex = evalBeforeWhite.abs() < 300;
    // Condition 2: was it the engine's top move?
    final isTopMove = topMovesBefore.isNotEmpty &&
        topMovesBefore.first.move == playedMoveUci;
    // Condition 3: large gap to second-best
    bool hasLargeGap = false;
    if (topMovesBefore.length >= 2) {
      final top1Eval = topMovesBefore[0].evaluation.toDouble();
      final top2Eval = topMovesBefore[1].evaluation.toDouble();
      hasLargeGap = (top1Eval - top2Eval).abs() >= 50;
    }
    // Condition 4: near-zero CPL
    final isNearPerfect = cpl < 10;

    if (isComplex && isTopMove && hasLargeGap && isNearPerfect) {
      return MoveClassification.brilliant;
    }
    if (cpl < 10) return MoveClassification.excellent;
    return MoveClassification.good;
  }

  /// Full per-move analysis of a PGN. Returns a [GameAnalysisSummary].
  Future<GameAnalysisSummary> analyzeGame(String pgn, {String? userSide}) async {
    final game = chess_lib.Chess();
    game.load_pgn(pgn);
    final states = game.history;
    final annotated = <MoveAnnotation>[];
    final replayBoard = chess_lib.Chess();

    for (int i = 0; i < states.length; i++) {
      final move = states[i].move;
      final fenBefore = replayBoard.fen;
      final turnBefore = i % 2 == 0 ? 'w' : 'b';

      // Only analyze user's moves if userSide is specified
      final isUserMove = userSide == null || userSide == turnBefore;

      final topMovesBefore = await _stockfish.getTopMoves(fenBefore, depth: 12);
      if (topMovesBefore.isEmpty) {
        replayBoard.move({'from': move.from, 'to': move.to, 'promotion': move.promotion});
        continue;
      }
      final bestEvalBefore = topMovesBefore.first.evaluation.toDouble();
      final evalBeforeWhite = turnBefore == 'w' ? bestEvalBefore : -bestEvalBefore;

      replayBoard.move({'from': move.from, 'to': move.to, 'promotion': move.promotion});
      final fenAfter = replayBoard.fen;
      final playedMoveUci = '${move.from}${move.to}';
      final san = playedMoveUci; // SAN approximation

      final topMovesAfter = await _stockfish.getTopMoves(fenAfter, depth: 12);
      if (topMovesAfter.isEmpty) continue;
      final bestEvalAfter = topMovesAfter.first.evaluation.toDouble();
      final evalAfterWhite = turnBefore == 'w' ? -bestEvalAfter : bestEvalAfter;

      // CPL: how much did this move cost the player (always positive)
      final swing = evalAfterWhite - evalBeforeWhite;
      final cpl = isUserMove
          ? (turnBefore == 'w' ? -swing : swing).clamp(0, double.infinity).toDouble()
          : 0.0;

      final classification = isUserMove
          ? _classifyMove(
              evalBeforeWhite: evalBeforeWhite,
              evalAfterWhite: evalAfterWhite,
              cpl: cpl,
              topMovesBefore: topMovesBefore,
              playedMoveUci: playedMoveUci,
            )
          : MoveClassification.good;

      final connectivityDelta = (cpl >= 200) ? -2.5 : (cpl >= 100 ? -0.8 : (cpl < 10 ? 1.2 : 0.3));

      annotated.add(MoveAnnotation(
        moveIndex: i,
        fen: fenBefore,
        san: san,
        evalBefore: evalBeforeWhite,
        evalAfter: evalAfterWhite,
        cpl: cpl,
        classification: classification,
        connectivityDelta: connectivityDelta,
      ));
    }

    return GameAnalysisSummary(
      pgn: pgn,
      userSide: userSide,
      annotatedMoves: annotated,
    );
  }

  /// Legacy: finds blunder swing spots (used by AnalysisView).
  Future<List<SwingSpot>> findSwingSpots(String pgn, {String? userSide}) async {
    final summary = await analyzeGame(pgn, userSide: userSide);
    return summary.annotatedMoves
        .where((m) => m.classification == MoveClassification.blunder ||
                      m.classification == MoveClassification.mistake)
        .map((m) => SwingSpot(
              moveIndex: m.moveIndex,
              fenBefore: m.fen,
              movePlayedSan: m.san,
              evalBefore: m.evalBefore,
              evalAfter: m.evalAfter,
              swing: m.evalAfter - m.evalBefore,
              connectivityDelta: m.connectivityDelta,
            ))
        .toList();
  }
}

// ============================================
// LEGACY SWING SPOT (backward compatibility)
// ============================================
class SwingSpot {
  final int moveIndex;
  final String fenBefore;
  final String movePlayedSan;
  final double evalBefore;
  final double evalAfter;
  final double swing;
  final double connectivityDelta;

  SwingSpot({
    required this.moveIndex,
    required this.fenBefore,
    required this.movePlayedSan,
    required this.evalBefore,
    required this.evalAfter,
    required this.swing,
    required this.connectivityDelta,
  });
}
