import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists training steps and updates user stats.
class TrainingRepository {
  final _client = Supabase.instance.client;

  /// Returns the current user's profile id, or null if not found.
  Future<String?> getProfileId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final res = await _client
        .from('profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    return res?['id'] as String?;
  }

  /// Returns the full user profile including engine preferences
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final res = await _client
        .from('profiles')
        .select('id, connectivity_weight, response_weight, influence_weight, engine_mode, avatar_url, total_aura')
        .eq('user_id', userId)
        .maybeSingle();
    return res != null ? Map<String, dynamic>.from(res) : null;
  }

  /// Uploads a face image to Supabase and updates profile metadata.
  Future<String?> uploadAvatar(File file) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final fileExt = file.path.split('.').last;
    final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'avatars/$fileName';

    await _client.storage.from('avatars').upload(filePath, file);

    final avatarUrl = _client.storage.from('avatars').getPublicUrl(filePath);
    await _updateProfileAvatar(userId, avatarUrl);

    return avatarUrl;
  }

  Future<void> _updateProfileAvatar(String userId, String avatarUrl) async {
    await _client
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('user_id', userId);
  }

  /// Returns position id for this FEN. Inserts the position if it doesn't exist.
  Future<String> getOrCreatePositionId(String fen) async {
    final existing = await _client
        .from('positions')
        .select('id')
        .eq('fen', fen)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    final sideToMove = fen.split(' ').length >= 2 ? fen.split(' ')[1] : 'w';
    final insert = await _client.from('positions').insert({
      'fen': fen,
      'side_to_move': sideToMove,
    }).select('id').single();
    return insert['id'] as String;
  }

  /// Records one training step and updates user stats.
  Future<void> recordSession({
    required String profileId,
    required String positionId,
    required String chosenMove,
    int? responseLatencyMs,
    required String outcome,
    required int auraEarned,
  }) async {
    await _client.from('training_sessions').insert({
      'profile_id': profileId,
      'position_id': positionId,
      'chosen_move': chosenMove,
      'response_latency_ms': responseLatencyMs,
      'outcome': outcome,
      'feedback_shown': true,
      'aura_earned': auraEarned,
    });

    await _updateUserStats(profileId, auraEarned);
  }

  Future<void> _updateUserStats(String profileId, int auraEarned) async {
    final res = await _client
        .from('user_stats')
        .select('total_aura, current_streak, longest_streak, last_training_date')
        .eq('profile_id', profileId)
        .single();

    final totalAura = (res['total_aura'] as int? ?? 0) + auraEarned;
    final lastDate = res['last_training_date'] != null
        ? DateTime.parse(res['last_training_date'] as String)
        : null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int newStreak = res['current_streak'] as int? ?? 0;
    if (lastDate == null) {
      newStreak = 1;
    } else {
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      if (lastDay == yesterday) {
        newStreak += 1;
      } else if (lastDay != today) {
        newStreak = 1;
      }
    }
    final longest = res['longest_streak'] as int? ?? 0;
    final newLongest = newStreak > longest ? newStreak : longest;

    await _client.from('user_stats').update({
      'total_aura': totalAura,
      'current_streak': newStreak,
      'longest_streak': newLongest,
      'positions_trained': (res['positions_trained'] as int? ?? 0) + 1,
      'last_training_date': today.toIso8601String().split('T').first,
      'updated_at': now.toIso8601String(),
      'consistency_score': _calculateNewConsistency(res['consistency_score'] as double? ?? 0, lastDate),
    }).eq('profile_id', profileId);
  }

  double _calculateNewConsistency(double currentScore, DateTime? lastDate) {
    if (lastDate == null) return 1.0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final diff = today.difference(lastDay).inDays;

    if (diff <= 0) return currentScore; // Already updated today
    if (diff == 1) return (currentScore + 1.0).clamp(0.0, 100.0); // Consecutive day bonus
    
    // "Slow Leak" - sink by 0.5 per missed day
    return (currentScore - (diff * 0.5)).clamp(0.0, 100.0);
  }

  /// Fetches current user stats for the given profile.
  Future<Map<String, dynamic>?> getUserStats(String profileId) async {
    final res = await _client
        .from('user_stats')
        .select('total_aura, current_streak, longest_streak, positions_trained, consistency_score')
        .eq('profile_id', profileId)
        .maybeSingle();
    return res != null ? Map<String, dynamic>.from(res) : null;
  }
  /// Fetches the top players ordered by total Aura.
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    final res = await _client
        .from('user_stats')
        .select('''
          total_aura,
          current_streak,
          profiles:profile_id (
            display_name,
            avatar_variant,
            avatar_background
          )
        ''')
        .order('total_aura', ascending: false)
        .limit(limit);
  
    return List<Map<String, dynamic>>.from(res);
  }

  /// Fetches the most recent training activities across the community.
  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 15}) async {
    final res = await _client
        .from('training_sessions')
        .select('''
          id,
          created_at,
          outcome,
          aura_earned,
          positions:position_id (
            fen,
            tags
          ),
          profiles:profile_id (
            display_name,
            avatar_variant,
            avatar_background
          )
        ''')
        .order('created_at', ascending: false)
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(res);
  }
}
