// ============================================================
// COMBINED PLATFORM WAREHOUSE — Normalized Game Model
// Both Chess.com and Lichess raw data maps into WarehouseGame.
// ============================================================

/// The source platform a game originated from.
enum GamePlatform { chessCom, lichess }

extension GamePlatformExtension on GamePlatform {
  String get label => this == GamePlatform.chessCom ? 'Chess.com' : 'Lichess';
  String get key   => this == GamePlatform.chessCom ? 'chess_com' : 'lichess';
}

/// Broad player-tier classification based on rating.
/// These thresholds align with Lichess/Chess.com community percentiles.
enum PlayerTier {
  beginner,     // < 1000
  casual,       // 1000–1399
  intermediate, // 1400–1799
  advanced,     // 1800–2199
  expert,       // 2200–2499
  professional, // 2500+  (titled / tournament players)
}

extension PlayerTierExtension on PlayerTier {
  String get label {
    switch (this) {
      case PlayerTier.beginner:     return 'Beginner';
      case PlayerTier.casual:       return 'Casual';
      case PlayerTier.intermediate: return 'Intermediate';
      case PlayerTier.advanced:     return 'Advanced';
      case PlayerTier.expert:       return 'Expert';
      case PlayerTier.professional: return 'Professional';
    }
  }

  /// Returns the ONNX model filename to use for this tier's predictions.
  /// Separate ONNX files keep amateur and professional pattern spaces isolated.
  String get onnxModelFile {
    switch (this) {
      case PlayerTier.beginner:
      case PlayerTier.casual:
        return 'model_amateur_low.onnx';
      case PlayerTier.intermediate:
        return 'model_amateur_mid.onnx';
      case PlayerTier.advanced:
        return 'model_amateur_high.onnx';
      case PlayerTier.expert:
        return 'model_expert.onnx';
      case PlayerTier.professional:
        return 'model_professional.onnx';
    }
  }

  static PlayerTier fromRating(int rating) {
    if (rating < 1000) return PlayerTier.beginner;
    if (rating < 1400) return PlayerTier.casual;
    if (rating < 1800) return PlayerTier.intermediate;
    if (rating < 2200) return PlayerTier.advanced;
    if (rating < 2500) return PlayerTier.expert;
    return PlayerTier.professional;
  }
}

// --------------------------------------------------------
// NORMALIZED GAME — single canonical shape for warehouse
// --------------------------------------------------------
class WarehouseGame {
  final String platformId;       // e.g. chess.com URL or lichess game ID
  final GamePlatform platform;
  final String pgn;

  // Players
  final String whiteUsername;
  final String blackUsername;
  final int    whiteRating;
  final int    blackRating;
  final PlayerTier whiteTier;
  final PlayerTier blackTier;

  // Game metadata
  final String  timeControl;     // e.g. "600", "blitz", "bullet"
  final bool    rated;
  final String  result;          // "1-0" | "0-1" | "1/2-1/2"
  final DateTime playedAt;

  // Optional: populated after analysis
  final String? userSide;        // 'w' or 'b' — which side belongs to the app user
  final PlayerTier? userTier;    // derived from the user's side rating

  WarehouseGame({
    required this.platformId,
    required this.platform,
    required this.pgn,
    required this.whiteUsername,
    required this.blackUsername,
    required this.whiteRating,
    required this.blackRating,
    required this.timeControl,
    required this.rated,
    required this.result,
    required this.playedAt,
    this.userSide,
    this.userTier,
  })  : whiteTier = PlayerTierExtension.fromRating(whiteRating),
        blackTier = PlayerTierExtension.fromRating(blackRating);

  /// Convenience: opponent's username relative to [appUsername].
  String opponentUsername(String appUsername) {
    final lc = appUsername.toLowerCase();
    return whiteUsername.toLowerCase() == lc ? blackUsername : whiteUsername;
  }

  /// Convenience: opponent's rating relative to [appUsername].
  int opponentRating(String appUsername) {
    final lc = appUsername.toLowerCase();
    return whiteUsername.toLowerCase() == lc ? blackRating : whiteRating;
  }

  /// Serialises to a Supabase-compatible map (platform-agnostic).
  Map<String, dynamic> toSupabaseMap(String profileId) => {
    'profile_id':       profileId,
    'platform':         platform.key,
    'platform_game_id': platformId,
    'pgn':              pgn,
    'white_username':   whiteUsername,
    'black_username':   blackUsername,
    'white_rating':     whiteRating,
    'black_rating':     blackRating,
    'white_tier':       whiteTier.name,
    'black_tier':       blackTier.name,
    'time_control':     timeControl,
    'rated':            rated,
    'result':           result,
    'played_at':        playedAt.toIso8601String(),
    if (userSide != null) 'user_side': userSide,
    if (userTier != null) 'user_tier': userTier!.name,
  };
}
