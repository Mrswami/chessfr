import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../training/training_repository.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _repository = TrainingRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _topPlayers = [];
  String _sortBy = 'xp'; // 'xp' or 'streak'

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getLeaderboard(limit: 50);
      if (mounted) {
        setState(() {
          _topPlayers = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Global Leaderboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _topPlayers.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildPodium(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _topPlayers.length > 3 ? _topPlayers.length - 3 : 0,
                        itemBuilder: (context, index) {
                          final player = _topPlayers[index + 3];
                          return _buildListRow(player, index + 4);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPodium() {
    if (_topPlayers.isEmpty) return const SizedBox();
    
    final first = _topPlayers[0];
    final second = _topPlayers.length > 1 ? _topPlayers[1] : null;
    final third = _topPlayers.length > 2 ? _topPlayers[2] : null;

    return Container(
      height: 280,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null) _buildPodiumSpot(second, 2, 140, Colors.grey.shade400),
          _buildPodiumSpot(first, 1, 180, Colors.amber),
          if (third != null) _buildPodiumSpot(third, 3, 120, Colors.brown.shade400),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot(Map<String, dynamic> player, int rank, double height, Color color) {
    final profile = player['profiles'] as Map<String, dynamic>?;
    final name = profile?['display_name'] ?? 'Player';
    final xp = player['total_xp'] ?? 0;
    
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getAvatarEmoji(profile),
            style: const TextStyle(fontSize: 40),
          ).animate().scale(delay: (rank * 100).ms),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$xp XP',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.8), color.withOpacity(0.2)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.black,
                ),
              ),
            ),
          ).animate().slideY(begin: 1.0, end: 0.0, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  Widget _buildListRow(Map<String, dynamic> player, int rank) {
    final profile = player['profiles'] as Map<String, dynamic>?;
    final name = profile?['display_name'] ?? 'Player';
    final xp = player['total_xp'] ?? 0;
    final streak = player['current_streak'] ?? 0;

    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white12,
          child: Text(
            rank.toString(),
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(_getAvatarEmoji(profile), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '$xp XP • $streak Day Streak 🔥',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white.withOpacity(0.2),
        ),
      ),
    ).animate().fadeIn(delay: (rank * 5).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.white12),
          const SizedBox(height: 16),
          Text(
            'No players yet.',
            style: TextStyle(color: Colors.white24, fontSize: 18),
          ),
        ],
      ),
    );
  }

  String _getAvatarEmoji(Map<String, dynamic>? profile) {
    final variant = profile?['avatar_variant'] as String? ?? 'classic';
    switch (variant) {
      case 'jolly': return '😄🎅';
      case 'cool': return '😎🎅';
      case 'sleepy': return '😴🎅';
      case 'king': return '🤴🎅';
      case 'robot': return '🤖🎅';
      case 'space': return '🚀🎅';
      case 'ninja': return '🥷🎅';
      default: return '🎅';
    }
  }
}
