import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../training/training_repository.dart';

class SocialHubScreen extends StatefulWidget {
  const SocialHubScreen({super.key});

  @override
  State<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends State<SocialHubScreen> with SingleTickerProviderStateMixin {
  final _repository = TrainingRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _topPlayers = [];
  List<Map<String, dynamic>> _activities = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final players = await _repository.getLeaderboard(limit: 20);
      final feed = await _repository.getRecentActivity(limit: 15);
      
      if (mounted) {
        setState(() {
          _topPlayers = players;
          _activities = feed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading hub: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Community Pulse'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'COMMUNITY PULSE'),
            Tab(text: 'HALL OF FAME'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivityFeed(),
                _buildContributorsList(),
              ],
            ),
    );
  }

  Widget _buildActivityFeed() {
    if (_activities.isEmpty) return _buildEmptyState('No active sessions yet.');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        final profile = activity['profiles'] as Map<String, dynamic>?;
        final position = activity['positions'] as Map<String, dynamic>?;
        final name = profile?['display_name'] ?? 'A player';
        final time = DateTime.parse(activity['created_at']).toLocal();
        final xp = activity['xp_earned'] ?? 0;
        final outcome = activity['outcome'] ?? 'solved';

        return Card(
          color: Colors.white.withOpacity(0.03),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCircularAvatar(profile, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _formatTime(time),
                            style: const TextStyle(color: Colors.white24, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          children: [
                            TextSpan(
                              text: outcome == 'correct' ? 'just solved ' : 'attempted ',
                              style: TextStyle(color: outcome == 'correct' ? Colors.greenAccent : Colors.white60),
                            ),
                            const TextSpan(text: 'a technical puzzle '),
                            TextSpan(
                              text: '+${xp}xp',
                              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // "Watching" Preview Placeholder
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.cyan.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.remove_red_eye_rounded, size: 14, color: Colors.cyanAccent),
                            const SizedBox(width: 8),
                            const Text(
                              'Watch solving pattern',
                              style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              (position?['tags'] as List?)?.first?.toString().toUpperCase() ?? 'TACTICAL',
                              style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.1),
                            ),
                          ],
                        ),
                      ).animate().shimmer(duration: 2.seconds, color: Colors.white10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildContributorsList() {
    if (_topPlayers.isEmpty) return _buildEmptyState('Community is just starting out.');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topPlayers.length,
      itemBuilder: (context, index) {
        final player = _topPlayers[index];
        final profile = player['profiles'] as Map<String, dynamic>?;
        final name = profile?['display_name'] ?? 'Player';
        final xp = player['total_xp'] ?? 0;
        final streak = player['current_streak'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: index < 3 ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: index < 3 ? Colors.amber.withOpacity(0.2) : Colors.transparent,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                _buildCircularAvatar(profile, size: 44),
                if (index < 3)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                    child: const Icon(Icons.workspace_premium, size: 12, color: Colors.black),
                  ),
              ],
            ),
            title: Text(
              name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Veteran Contributor • $streak 🔥 streak',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$xp',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.black, fontSize: 16),
                ),
                const Text('XP', style: TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 30).ms);
      },
    );
  }

  Widget _buildCircularAvatar(Map<String, dynamic>? profile, {double size = 50}) {
    final emoji = _getAvatarEmoji(profile);
    final bg = _getBackgroundGradient(profile?['avatar_background']);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: bg,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.diversity_3_rounded, size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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

  List<Color> _getBackgroundGradient(String? background) {
    switch (background) {
      case 'blue': return [Colors.blue.shade900, Colors.blue.shade700];
      case 'green': return [Colors.green.shade900, Colors.green.shade700];
      case 'purple': return [Colors.purple.shade900, Colors.purple.shade700];
      case 'gold': return [const Color(0xFFB8860B), const Color(0xFFFFD700)];
      case 'fire': return [Colors.red.shade900, Colors.orange.shade800];
      case 'forest': return [const Color(0xFF003300), const Color(0xFF006600)];
      case 'arctic': return [Colors.cyan.shade900, Colors.cyan.shade100];
      default: return [Colors.grey.shade900, Colors.grey.shade800];
    }
  }
}
