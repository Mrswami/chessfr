import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows a compact Brilliant Move Tracker card for the Home Screen.
/// Displays the user's brilliant move history over recent games.
class BrilliantTrackerWidget extends StatefulWidget {
  const BrilliantTrackerWidget({super.key});

  @override
  State<BrilliantTrackerWidget> createState() => _BrilliantTrackerWidgetState();
}

class _BrilliantTrackerWidgetState extends State<BrilliantTrackerWidget> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _recentAnalyses = [];
  bool _isLoading = true;
  int _totalBrilliant = 0;

  @override
  void initState() {
    super.initState();
    _loadBrilliantStats();
  }

  Future<void> _loadBrilliantStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get this user's profile_id
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (profile == null) return;

      // Fetch the last 10 analyzed games
      final analyses = await _supabase
          .from('game_analyses')
          .select('brilliant_count, blunder_count, game_result, created_at')
          .eq('profile_id', profile['id'])
          .order('created_at', ascending: false)
          .limit(10);

      int total = 0;
      for (final a in analyses) {
        total += (a['brilliant_count'] as int? ?? 0);
      }

      if (mounted) {
        setState(() {
          _recentAnalyses = List<Map<String, dynamic>>.from(analyses);
          _totalBrilliant = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('BrilliantTracker load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            Colors.amber.shade900.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.amber,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 24))
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 2000.ms, color: Colors.amber),
                    const SizedBox(width: 10),
                    const Text(
                      'BRILLIANT MOVES',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'Last 10 games',
                        style: TextStyle(
                          color: Colors.amber.shade200,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_recentAnalyses.isEmpty)
                  Text(
                    'Analyze your first game to start\ntracking brilliant moves!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  )
                else ...[
                  // Big number display
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_totalBrilliant',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ).animate().slideY(begin: 0.3, end: 0).fadeIn(),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'brilliant\nmoves',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Per-game bars
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(_recentAnalyses.length, (i) {
                      final game = _recentAnalyses[i];
                      final brilliant = game['brilliant_count'] as int? ?? 0;
                      final blunders = game['blunder_count'] as int? ?? 0;
                      final isWin = game['game_result'] == 'win';
                      final maxBar = 5;
                      final barHeight = (brilliant / maxBar).clamp(0.1, 1.0) * 48;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (brilliant > 0)
                                Text(
                                  '$brilliant',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Container(
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: brilliant > 0
                                      ? Colors.amber.withValues(alpha: 0.8)
                                      : (blunders > 0
                                          ? Colors.red.withValues(alpha: 0.4)
                                          : Colors.white.withValues(alpha: 0.1)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ).animate().slideY(begin: 1, end: 0, delay: (i * 50).ms),
                              const SizedBox(height: 4),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isWin ? Colors.green : Colors.red.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }
}
