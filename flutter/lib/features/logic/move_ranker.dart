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
    final String engineMode = userProfile['engine_mode'] ?? 'stockfish';
    final bool isDankFish = engineMode == 'dankfish';

    // 1. Get profile weights (defaulting if missing)
    // For DankFish, we use specific cognitive weights
    final double connWeight = userProfile['connectivity_weight'] ?? (isDankFish ? 0.6 : 0.3);
    final double respWeight = userProfile['response_weight'] ?? (isDankFish ? 0.2 : 0.1);
    final double inflWeight = userProfile['influence_weight'] ?? (isDankFish ? 0.2 : 0.1);
    
    // Engine trust is lower in DankFish to allow style-aligned moves to surface
    final double engineWeight = isDankFish ? 0.4 : 0.7;

    List<RankedMove> ranked = [];

    for (var move in engineMoves) {
      // 2. Calculate design metrics
      final metrics = ConnectivityCalculator.calculate(fen, move.san);

      // 3. Normalize Engine Score (cp to 0-1 range roughly)
      // Assuming evaluation is in centipawns. +100 cp = +1.0 score.
      double engineScore = (move.evaluation / 100.0).clamp(-5.0, 5.0);
      double normalizedEngine = (engineScore + 5) / 10; 

      // 4. Calculate Composite Design Score
      // In DankFish, we balance between all three metrics
      double designScore = (metrics.connectivityGain * connWeight) + 
                          (metrics.responseGain * respWeight) + 
                          (metrics.influenceGain * inflWeight);
      
      // Bonus for bridge building (fundamental to our design universe)
      if (metrics.isBridge) designScore += 0.2;
      
      // 5. Final Composite Score
      double finalScore = (normalizedEngine * engineWeight) + (designScore * (1 - engineWeight));

      ranked.add(RankedMove(
        moveSan: move.san,
        finalScore: finalScore,
        engineEval: move.evaluation,
        designMetrics: metrics,
        explanation: _generateExplanation(metrics, move.evaluation, isDankFish),
      ));
    }

    // Sort descending by final score
    ranked.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return ranked;
  }

  String _generateExplanation(DesignMetrics metrics, int eval, bool isDankFish) {
    if (isDankFish) {
      if (metrics.isBridge) return '🎅 DankFish says: Connect those pieces! (Structure +)';
      if (metrics.connectivityGain > 0.5) return '🎅 Solid connection move.';
      return '🎅 Keeping it tight and organized.';
    }
    
    if (metrics.isBridge) return 'Strong positional bridge.';
    if (eval > 100) return 'Solid material advantage.';
    return 'Thematically consistent move.';
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
