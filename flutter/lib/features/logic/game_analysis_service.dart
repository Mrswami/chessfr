import 'package:chess/chess.dart' as chess_lib;
import 'stockfish_service.dart';
import 'warehouse_game.dart';

// ============================================================
// MOVE CLASSIFICATION
// ============================================================
enum MoveClassification {
  brilliant,   // ⭐ Only correct move in a complex position
  excellent,   // Near-best move, low CPL
  good,        // Solid, within acceptable range
  inaccuracy,  // CPL 50–100
  mistake,     // CPL 100–200
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

  String get shortName => toString().split('.').last;
}

// ============================================================
// GAME PHASE
// Heuristic: opening = first 10 half-moves, endgame = ≤ 6 pieces
// ============================================================
enum GamePhase { opening, middlegame, endgame }

GamePhase _detectPhase(chess_lib.Chess board, int halfMoveIndex) {
  if (halfMoveIndex < 10) return GamePhase.opening;

  // Count material (non-pawn, non-king pieces)
  int pieces = 0;
  for (int sq = 0; sq < 128; sq++) {
    if (sq & 0x88 != 0) continue;
    final piece = board.get(chess_lib.Chess.algebraic(sq));
    if (piece != null &&
        piece.type != chess_lib.PieceType.KING &&
        piece.type != chess_lib.PieceType.PAWN) {
      pieces++;
    }
  }
  return pieces <= 6 ? GamePhase.endgame : GamePhase.middlegame;
}

// ============================================================
// MOVE ANNOTATION
// ============================================================
class MoveAnnotation {
  final int moveIndex;
  final GamePhase phase;
  final String fen;
  final String san;               // SAN notation
  final String uci;               // UCI e.g. "e2e4"
  final double evalBefore;        // White-normalised centipawns
  final double evalAfter;
  final double cpl;               // Centipawn Loss (always ≥ 0)
  final MoveClassification classification;
  final double connectivityDelta; // Aura score delta
  final bool isCapture;
  final bool isCheck;

  MoveAnnotation({
    required this.moveIndex,
    required this.phase,
    required this.fen,
    required this.san,
    required this.uci,
    required this.evalBefore,
    required this.evalAfter,
    required this.cpl,
    required this.classification,
    required this.connectivityDelta,
    required this.isCapture,
    required this.isCheck,
  });

  Map<String, dynamic> toJson() => {
    'moveIndex':         moveIndex,
    'phase':             phase.name,
    'fen':               fen,
    'san':               san,
    'uci':               uci,
    'evalBefore':        evalBefore,
    'evalAfter':         evalAfter,
    'cpl':               cpl,
    'classification':    classification.shortName,
    'connectivityDelta': connectivityDelta,
    'isCapture':         isCapture,
    'isCheck':           isCheck,
  };
}

// ============================================================
// PHASE ACCURACY SUMMARY
// Tracks average CPL broken down by opening/middlegame/endgame.
// This is the key contrast metric between amateur and pro tiers.
// ============================================================
class PhaseAccuracy {
  final GamePhase phase;
  final int       moveCount;
  final double    avgCpl;       // lower = better
  final double    accuracyPct;  // 0–100, based on CPL → accuracy curve

  PhaseAccuracy({
    required this.phase,
    required this.moveCount,
    required this.avgCpl,
    required this.accuracyPct,
  });

  Map<String, dynamic> toJson() => {
    'phase':       phase.name,
    'moveCount':   moveCount,
    'avgCpl':      avgCpl,
    'accuracyPct': accuracyPct,
  };

  /// CPL → accuracy conversion (Chess.com / Lichess style sigmoid approximation).
  static double cplToAccuracy(double cpl) {
    // Lichess formula approximation: accuracy = 103.1668 * exp(-0.04354 * cpl) - 3.1668
    // Clamped to [0, 100].
    final raw = 103.1668 * (1 / (1 + 0.04354 * cpl)) - 3.1668;
    return raw.clamp(0.0, 100.0);
  }
}

// ============================================================
// GAME ANALYSIS SUMMARY
// ============================================================
class GameAnalysisSummary {
  final String pgn;
  final String? userSide;
  final PlayerTier? playerTier;
  final List<MoveAnnotation> annotatedMoves;

  // Pre-computed phase accuracy breakdowns
  final PhaseAccuracy openingAccuracy;
  final PhaseAccuracy middlegameAccuracy;
  final PhaseAccuracy endgameAccuracy;

  GameAnalysisSummary({
    required this.pgn,
    this.userSide,
    this.playerTier,
    required this.annotatedMoves,
    required this.openingAccuracy,
    required this.middlegameAccuracy,
    required this.endgameAccuracy,
  });

  // -- Counts -------------------------------------------------
  int get brilliantCount  => _count(MoveClassification.brilliant);
  int get excellentCount  => _count(MoveClassification.excellent);
  int get goodCount       => _count(MoveClassification.good);
  int get inaccuracyCount => _count(MoveClassification.inaccuracy);
  int get mistakeCount    => _count(MoveClassification.mistake);
  int get blunderCount    => _count(MoveClassification.blunder);

  List<MoveAnnotation> get brilliantMoves => _filter(MoveClassification.brilliant);
  List<MoveAnnotation> get blunderMoves   => _filter(MoveClassification.blunder);

  int    _count(MoveClassification c) => annotatedMoves.where((m) => m.classification == c).length;
  List<MoveAnnotation> _filter(MoveClassification c) =>
      annotatedMoves.where((m) => m.classification == c).toList();

  /// Overall average CPL across all user moves.
  double get overallAvgCpl {
    final userMoves = annotatedMoves.where((m) => m.cpl > 0).toList();
    if (userMoves.isEmpty) return 0;
    return userMoves.map((m) => m.cpl).reduce((a, b) => a + b) / userMoves.length;
  }

  /// Overall accuracy percentage.
  double get overallAccuracyPct => PhaseAccuracy.cplToAccuracy(overallAvgCpl);

  // -- Supabase map -------------------------------------------
  Map<String, dynamic> toSupabaseMap(String profileId, {
    required String platformGameId,
    required String platform,
    String? opponentUsername,
    int?    opponentRating,
    String? timeControl,
    String? gameResult,
  }) => {
    'profile_id':          profileId,
    'platform':            platform,
    'platform_game_id':    platformGameId,
    'pgn':                 pgn,
    'user_side':           userSide,
    if (playerTier != null) 'player_tier': playerTier!.name,
    if (opponentUsername != null) 'opponent_username': opponentUsername,
    if (opponentRating   != null) 'opponent_rating':   opponentRating,
    if (timeControl      != null) 'time_control':      timeControl,
    if (gameResult       != null) 'game_result':       gameResult,
    'total_moves':         annotatedMoves.length,
    'brilliant_count':     brilliantCount,
    'excellent_count':     excellentCount,
    'good_count':          goodCount,
    'inaccuracy_count':    inaccuracyCount,
    'mistake_count':       mistakeCount,
    'blunder_count':       blunderCount,
    'overall_avg_cpl':     overallAvgCpl,
    'overall_accuracy':    overallAccuracyPct,
    'opening_accuracy':    openingAccuracy.toJson(),
    'middlegame_accuracy': middlegameAccuracy.toJson(),
    'endgame_accuracy':    endgameAccuracy.toJson(),
    'annotated_moves':     annotatedMoves.map((m) => m.toJson()).toList(),
    'brilliant_moves':     brilliantMoves.map((m) => m.toJson()).toList(),
  };
}

// ============================================================
// GAME ANALYSIS SERVICE
// ============================================================
class GameAnalysisService {
  final StockfishService _stockfish;

  GameAnalysisService(this._stockfish);

  // -------------------------------------------------------
  // MOVE CLASSIFIER
  // Brilliant: complex position + top engine move + big gap + near-zero CPL
  // -------------------------------------------------------
  MoveClassification _classifyMove({
    required double evalBeforeWhite,
    required double cpl,
    required List topMovesBefore,
    required String playedUci,
  }) {
    if (cpl >= 200) return MoveClassification.blunder;
    if (cpl >= 100) return MoveClassification.mistake;
    if (cpl >=  50) return MoveClassification.inaccuracy;

    final isComplex  = evalBeforeWhite.abs() < 300;
    final isTopMove  = topMovesBefore.isNotEmpty &&
                       topMovesBefore.first.move == playedUci;
    bool hasLargeGap = false;
    if (topMovesBefore.length >= 2) {
      final gap = (topMovesBefore[0].evaluation.toDouble() -
                   topMovesBefore[1].evaluation.toDouble()).abs();
      hasLargeGap = gap >= 50;
    }
    final isNearPerfect = cpl < 10;

    if (isComplex && isTopMove && hasLargeGap && isNearPerfect) {
      return MoveClassification.brilliant;
    }
    if (cpl < 10) return MoveClassification.excellent;
    return MoveClassification.good;
  }

  // -------------------------------------------------------
  // CPL → connectivity (Aura) delta
  // -------------------------------------------------------
  static double _connectivityDelta(double cpl) {
    if (cpl >= 200) return -2.5;
    if (cpl >= 100) return -0.8;
    if (cpl >=  50) return -0.2;
    if (cpl <   10) return  1.2;
    return 0.3;
  }

  // -------------------------------------------------------
  // PHASE ACCURACY BUILDER
  // -------------------------------------------------------
  PhaseAccuracy _buildPhaseAccuracy(
    List<MoveAnnotation> moves,
    GamePhase phase,
  ) {
    final phaseMoves = moves.where((m) => m.phase == phase && m.cpl > 0).toList();
    if (phaseMoves.isEmpty) {
      return PhaseAccuracy(
        phase: phase, moveCount: 0, avgCpl: 0, accuracyPct: 100,
      );
    }
    final avg = phaseMoves.map((m) => m.cpl).reduce((a, b) => a + b) /
                phaseMoves.length;
    return PhaseAccuracy(
      phase:      phase,
      moveCount:  phaseMoves.length,
      avgCpl:     avg,
      accuracyPct: PhaseAccuracy.cplToAccuracy(avg),
    );
  }

  // -------------------------------------------------------
  // FULL GAME ANALYSIS
  // Pass [playerTier] to tag the summary for ONNX routing.
  // -------------------------------------------------------
  Future<GameAnalysisSummary> analyzeGame(
    String pgn, {
    String?     userSide,
    PlayerTier? playerTier,
    int         depth = 14,
  }) async {
    final game = chess_lib.Chess();
    game.load_pgn(pgn);
    final states      = game.history;
    final annotated   = <MoveAnnotation>[];
    final replayBoard = chess_lib.Chess();

    // Pre-extract SAN strings from the completed game's verbose move list.
    // We replay the full game on a throw-away board to get SAN for each half-move.
    final sanList = <String>[];
    {
      final sanBoard = chess_lib.Chess();
      for (final state in states) {
        final m = state.move;
        final verboseMoves = sanBoard.moves({'verbose': true});
        final matchedSan = verboseMoves.firstWhere(
          (v) => v['from'] == m.from && v['to'] == m.to,
          orElse: () => null,
        );
        sanList.add(matchedSan?['san'] as String? ?? '${m.from}${m.to}');
        sanBoard.move({'from': m.from, 'to': m.to, 'promotion': m.promotion});
      }
    }

    for (int i = 0; i < states.length; i++) {
      final move       = states[i].move;
      final fenBefore  = replayBoard.fen;
      final turnBefore = i % 2 == 0 ? 'w' : 'b';
      final isUserMove = userSide == null || userSide == turnBefore;

      final phase = _detectPhase(replayBoard, i);

      final topBefore = await _stockfish.getTopMoves(fenBefore, depth: depth);
      if (topBefore.isEmpty) {
        replayBoard.move({
          'from':      move.from,
          'to':        move.to,
          'promotion': move.promotion,
        });
        continue;
      }
      final bestEvalBefore  = topBefore.first.evaluation.toDouble();
      final evalBeforeWhite = turnBefore == 'w' ? bestEvalBefore : -bestEvalBefore;

      replayBoard.move({
        'from':      move.from,
        'to':        move.to,
        'promotion': move.promotion,
      });
      final fenAfter = replayBoard.fen;
      final uci = '${move.from}${move.to}';
      final String san = i < sanList.length ? sanList[i] : uci;

      final topAfter = await _stockfish.getTopMoves(fenAfter, depth: depth);
      if (topAfter.isEmpty) continue;
      final bestEvalAfter  = topAfter.first.evaluation.toDouble();
      final evalAfterWhite = turnBefore == 'w' ? -bestEvalAfter : bestEvalAfter;

      final swing = evalAfterWhite - evalBeforeWhite;
      final cpl = isUserMove
          ? (turnBefore == 'w' ? -swing : swing).clamp(0.0, double.infinity)
          : 0.0;

      final classification = isUserMove
          ? _classifyMove(
              evalBeforeWhite: evalBeforeWhite,
              cpl: cpl,
              topMovesBefore: topBefore,
              playedUci: uci,
            )
          : MoveClassification.good;

      annotated.add(MoveAnnotation(
        moveIndex:         i,
        phase:             phase,
        fen:               fenBefore,
        san:               san,
        uci:               uci,
        evalBefore:        evalBeforeWhite,
        evalAfter:         evalAfterWhite,
        cpl:               cpl,
        classification:    classification,
        connectivityDelta: _connectivityDelta(cpl),
        isCapture:         move.captured != null,
        isCheck:           replayBoard.in_check,
      ));
    }

    return GameAnalysisSummary(
      pgn:               pgn,
      userSide:          userSide,
      playerTier:        playerTier,
      annotatedMoves:    annotated,
      openingAccuracy:   _buildPhaseAccuracy(annotated, GamePhase.opening),
      middlegameAccuracy:_buildPhaseAccuracy(annotated, GamePhase.middlegame),
      endgameAccuracy:   _buildPhaseAccuracy(annotated, GamePhase.endgame),
    );
  }

  // -------------------------------------------------------
  // CONVENIENCE: analyze a WarehouseGame directly
  // Automatically resolves player tier and user side.
  // -------------------------------------------------------
  Future<GameAnalysisSummary> analyzeWarehouseGame(
    WarehouseGame game,
    String appUsername,
  ) async {
    final lc     = appUsername.toLowerCase();
    final side   = game.whiteUsername.toLowerCase() == lc ? 'w' : 'b';
    final rating = side == 'w' ? game.whiteRating : game.blackRating;
    final tier   = PlayerTierExtension.fromRating(rating);

    return analyzeGame(
      game.pgn,
      userSide:   side,
      playerTier: tier,
    );
  }

  // -------------------------------------------------------
  // LEGACY: findSwingSpots (backward compatibility)
  // -------------------------------------------------------
  Future<List<SwingSpot>> findSwingSpots(String pgn, {String? userSide}) async {
    final summary = await analyzeGame(pgn, userSide: userSide);
    return summary.annotatedMoves
        .where((m) =>
            m.classification == MoveClassification.blunder ||
            m.classification == MoveClassification.mistake)
        .map((m) => SwingSpot(
              moveIndex:       m.moveIndex,
              fenBefore:       m.fen,
              movePlayedSan:   m.san,
              evalBefore:      m.evalBefore,
              evalAfter:       m.evalAfter,
              swing:           m.evalAfter - m.evalBefore,
              connectivityDelta: m.connectivityDelta,
            ))
        .toList();
  }
}

// ============================================================
// LEGACY SWING SPOT (backward compatibility)
// ============================================================
class SwingSpot {
  final int    moveIndex;
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
