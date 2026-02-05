import 'design_metrics.dart';

class MoveRanker {
  static final MoveRanker _instance = MoveRanker._internal();
  factory MoveRanker() => _instance;
  MoveRanker._internal();

  /// Ranks moves based on Engine Eval + Design Metrics
  List<RankedMove> rankMoves(
    String fen,
    List<EngineMove> engineMoves,
    Map<String, dynamic> userProfile,
  ) {
    // 1. Get profile weights (defaulting if missing)
    final double designWeight = userProfile['connectivity_weight'] ?? 0.5;
    final double engineWeight = userProfile['engine_trust'] ?? 0.5;

    List<RankedMove> ranked = [];

    for (var move in engineMoves) {
      // 2. Calculate design metrics
      final metrics = ConnectivityCalculator.calculate(fen, move.san);

      // 3. Normalize Engine Score (cp to 0-1 range roughly)
      // Assuming evaluation is in centipawns. +100 cp = +1.0 score.
      double engineScore = (move.evaluation / 100.0).clamp(-5.0, 5.0);
      // Sigmoid-ish to keep it bounded
      double normalizedEngine = (engineScore + 5) / 10; 

      // 4. Normalize Design Score
      // Bridge is huge bonus. Gain is added.
      double designScore = (metrics.isBridge ? 1.0 : 0.0) + (metrics.connectivityGain * 0.5);
      
      // 5. Final Composite Score
      double finalScore = (normalizedEngine * engineWeight) + (designScore * designWeight);

      ranked.add(RankedMove(
        moveSan: move.san,
        finalScore: finalScore,
        engineEval: move.evaluation,
        designMetrics: metrics,
        explanation: _generateExplanation(metrics, move.evaluation),
      ));
    }

    // Sort descending
    ranked.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return ranked;
  }

  String _generateExplanation(DesignMetrics metrics, int eval) {
    if (metrics.isBridge) return 'Connects your islands! (Structure +)';
    if (eval > 100) return 'Winning material advantage.';
    return 'Solid developing move.';
  }
}

class EngineMove {
  final String san;
  final int evaluation; // centipawns
  EngineMove({required this.san, required this.evaluation});
}

class RankedMove {
  final String moveSan;
  final double finalScore;
  final int engineEval;
  final DesignMetrics designMetrics;
  final String explanation;

  RankedMove({
    required this.moveSan,
    required this.finalScore,
    required this.engineEval,
    required this.designMetrics,
    required this.explanation,
  });
}
