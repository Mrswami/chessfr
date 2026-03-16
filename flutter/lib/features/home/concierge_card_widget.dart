import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Concierge Card Feed — a daily AI-powered recommendation card
/// shown on the Home Screen, tailored to the user's cognitive profile and history.
class ConciergeCardWidget extends StatefulWidget {
  const ConciergeCardWidget({super.key});

  @override
  State<ConciergeCardWidget> createState() => _ConciergeCardWidgetState();
}

class _ConciergeCardWidgetState extends State<ConciergeCardWidget> {
  final _supabase = Supabase.instance.client;
  _ConciergeCard? _card;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _buildConciergeCard();
  }

  Future<void> _buildConciergeCard() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Fetch profile
      final profile = await _supabase
          .from('profiles')
          .select('id, cognitive_profile')
          .eq('user_id', user.id)
          .maybeSingle();
      if (profile == null) return;

      final profileId = profile['id'] as String;
      final cognitive = (profile['cognitive_profile'] as Map<String, dynamic>?) ?? {};
      final connectivityWeight = (cognitive['connectivity_weight'] as num?)?.toDouble() ?? 0.33;
      final responseWeight = (cognitive['response_weight'] as num?)?.toDouble() ?? 0.33;
      final influenceWeight = (cognitive['influence_weight'] as num?)?.toDouble() ?? 0.34;

      // 2. Fetch stats
      final stats = await _supabase
          .from('user_stats')
          .select('current_streak, total_aura')
          .eq('profile_id', profileId)
          .maybeSingle();
      final streak = (stats?['current_streak'] as int?) ?? 0;

      // 3. Fetch last 5 game analysis summaries to find weaknesses
      final analyses = await _supabase
          .from('game_analyses')
          .select('blunder_count, brilliant_count, game_result, weakness_tags')
          .eq('profile_id', profileId)
          .order('created_at', ascending: false)
          .limit(5);

      int totalBlunders = 0;
      int totalBrilliant = 0;
      List<String> weaknessTags = [];

      for (final a in analyses) {
        totalBlunders += (a['blunder_count'] as int? ?? 0);
        totalBrilliant += (a['brilliant_count'] as int? ?? 0);
        final tags = a['weakness_tags'] as List<dynamic>? ?? [];
        weaknessTags.addAll(tags.cast<String>());
      }

      // 4. Determine the best recommendation type using weighted scoring
      _card = _selectCard(
        streak: streak,
        totalBlunders: totalBlunders,
        totalBrilliant: totalBrilliant,
        connectivityWeight: connectivityWeight,
        responseWeight: responseWeight,
        influenceWeight: influenceWeight,
        weaknessTags: weaknessTags,
        hasGameHistory: analyses.isNotEmpty,
      );
    } catch (e) {
      debugPrint('Concierge error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Concierge Scoring Formula from Architecture Plan:
  /// Score = ConnectivityW × connectivity_relevance
  ///       + ResponseW × response_relevance
  ///       + InfluenceW × influence_relevance
  ///       + StreakBonus × 0.2
  ///       + WeaknessPenalty × weakness_match
  _ConciergeCard _selectCard({
    required int streak,
    required int totalBlunders,
    required int totalBrilliant,
    required double connectivityWeight,
    required double responseWeight,
    required double influenceWeight,
    required List<String> weaknessTags,
    required bool hasGameHistory,
  }) {
    // Score each card type
    final Map<String, double> scores = {};

    final streakBonus = streak > 3 ? 0.2 : 0.0;

    // PUZZLE card: good if response weight is high (fast reactive play weaknesses)
    scores['puzzle'] = responseWeight * 0.8 + streakBonus +
        (totalBlunders > 3 ? 0.3 : 0.0);

    // REVIEW card: good if they have game history with problems
    scores['review'] = hasGameHistory && totalBlunders > 0
        ? connectivityWeight * 0.5 + influenceWeight * 0.4 + 0.2
        : 0.0;

    // INSIGHT card: connectivity-heavy users love pattern stats
    scores['insight'] = connectivityWeight * 0.9 +
        (totalBrilliant > 0 ? 0.2 : 0.0);

    // CHALLENGE card (Hall of Fame): good for high-aura, on-streak players
    scores['challenge'] = streak > 2
        ? influenceWeight * 0.7 + streakBonus + 0.2
        : influenceWeight * 0.3;

    // STREAK PUSH: show if streak < 1 (needs motivation)
    scores['streak_push'] = streak == 0 ? 0.9 : (streak < 3 ? 0.5 : 0.1);

    // Pick the highest-scoring card
    final best = scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    switch (best) {
      case 'puzzle':
        return _ConciergeCard(
          type: 'puzzle',
          emoji: '🧩',
          title: 'Pattern Drill',
          subtitle: totalBlunders > 3
              ? 'You\'ve had $totalBlunders blunders recently.\nLet\'s sharpen your tactics.'
              : 'Your response timing is your strength.\nPush it further with a drill.',
          accentColor: const Color(0xFF0D9488),
          cta: 'START DRILL',
        );
      case 'review':
        return _ConciergeCard(
          type: 'review',
          emoji: '📖',
          title: 'Replay & Learn',
          subtitle: 'Your last game has moments worth\nrevisiting. Turn mistakes into lessons.',
          accentColor: const Color(0xFF8B5CF6),
          cta: 'REVIEW GAME',
        );
      case 'insight':
        return _ConciergeCard(
          type: 'insight',
          emoji: '📊',
          title: 'Connectivity Insight',
          subtitle: totalBrilliant > 0
              ? 'You\'ve found $totalBrilliant brilliant moves! ⭐\nYour pattern recognition is elite.'
              : 'High connectivity style detected.\nAnalyze a game to unlock your stats.',
          accentColor: Colors.cyanAccent,
          cta: 'SEE MY STATS',
        );
      case 'challenge':
        return _ConciergeCard(
          type: 'challenge',
          emoji: '🏆',
          title: 'Hall of Fame Challenge',
          subtitle: 'Can you find the move that made\nthe Hall of Fame? Prove yourself.',
          accentColor: Colors.amber,
          cta: 'TAKE CHALLENGE',
        );
      case 'streak_push':
      default:
        return _ConciergeCard(
          type: 'streak_push',
          emoji: '🔥',
          title: streak == 0 ? 'Start Your Streak' : 'Keep it Going',
          subtitle: streak == 0
              ? 'One session a day builds a grandmaster.\nLet\'s begin today.'
              : 'You\'re on a $streak-day streak!\nDon\'t break the chain.',
          accentColor: Colors.orange,
          cta: streak == 0 ? 'START NOW' : 'TRAIN TODAY',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: SizedBox(
            height: 24, width: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan),
          ),
        ),
      );
    }

    if (_card == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _card!.accentColor.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _card!.accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_card!.emoji, style: const TextStyle(fontSize: 36))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 1800.ms),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONCIERGE RECOMMENDS',
                  style: TextStyle(
                    color: _card!.accentColor.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _card!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _card!.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {}, // Will route to the corresponding feature
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _card!.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _card!.accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _card!.cta,
                      style: TextStyle(
                        color: _card!.accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05, end: 0);
  }
}

class _ConciergeCard {
  final String type;
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String cta;

  const _ConciergeCard({
    required this.type,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.cta,
  });
}
