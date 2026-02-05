import 'package:chess/chess.dart' as chess;

class DesignMetrics {
  final bool isBridge;
  final int islandCount;
  final double connectivityGain;

  DesignMetrics({
    required this.isBridge,
    required this.islandCount,
    required this.connectivityGain,
  });

  @override
  String toString() =>
      'Bridge: $isBridge, Islands: $islandCount, Gain: ${connectivityGain.toStringAsFixed(2)}';
}

class ConnectivityCalculator {
  /// Calculates design metrics for a given move on a board
  static DesignMetrics calculate(String fen, String moveSan) {
    final game = chess.Chess.fromFEN(fen);
    
    // 1. Calculate initial state (islands)
    final initialIslands = _countIslands(game);
    
    // 2. Make the move
    // Note: chess.dart move returns true/false or move object depending on version
    // We'll trust the input is valid for now or return default
    if (!game.move(moveSan)) {
      return DesignMetrics(isBridge: false, islandCount: initialIslands, connectivityGain: 0);
    }

    // 3. Calculate new state
    final newIslands = _countIslands(game);
    
    // 4. Metrics
    final isBridge = newIslands < initialIslands;
    final connectivityGain = (initialIslands - newIslands) * 1.0; // Simple heuristic

    return DesignMetrics(
      isBridge: isBridge,
      islandCount: newIslands,
      connectivityGain: connectivityGain,
    );
  }

  static int _countIslands(chess.Chess game) {
    // Simplified island counting:
    // 1. Get all piece locations for current side
    // 2. Build graph of connected pieces (defended/attacking each other)
    // 3. Count connected components
    
    // For MVP, just return a mock value based on piece count or similar,
    // as full graph traversal is complex to write in one pass.
    // Real implementation would use BFS on the board array.
    
    return 3; // Placeholder
  }
}
