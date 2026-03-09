import 'package:flutter/material.dart';
import '../training/widgets/mastery_path.dart';
import '../training/widgets/brain_balloon.dart';
import '../training/widgets/master_map.dart';
import '../training/training_repository.dart';

class MasteryScreen extends StatefulWidget {
  const MasteryScreen({super.key});

  @override
  State<MasteryScreen> createState() => _MasteryScreenState();
}

class _MasteryScreenState extends State<MasteryScreen> {
  final TrainingRepository _repo = TrainingRepository();
  int _totalXp = 0;
  double _consistencyScore = 0;
  int _currentLevel = 0;
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final profileId = await _repo.getProfileId();
    if (profileId == null) return;
    
    // Load stats
    final stats = await _repo.getUserStats(profileId);
    
    // Load profile for avatar_url
    final profile = await _repo.getProfile();
    
    if (mounted && stats != null) {
      final xp = stats['total_xp'] as int? ?? 0;
      final consistency = (stats['consistency_score'] as num? ?? 0).toDouble();
      setState(() {
        _totalXp = xp;
        _consistencyScore = consistency;
        _avatarUrl = profile?['avatar_url'];
        // Simple level calculation: Level = totalXp / 500
        _currentLevel = (xp / 500).floor();
        _isLoading = false;
      });
    }
  }

  Color _getAtmosphereColor() {
    if (_consistencyScore < 3) return const Color(0xFF0F0F0F); // Ground / Fog
    if (_consistencyScore < 7) return const Color(0xFF001220); // Deep Sky
    if (_consistencyScore < 14) return const Color(0xFF000B14); // Stratosphere
    return const Color(0xFF010101); // Space
  }

  @override
  Widget build(BuildContext context) {
    final atmosphereColor = _getAtmosphereColor();
    
    return Scaffold(
      backgroundColor: atmosphereColor,
      appBar: AppBar(
        title: const Text('COGNITIVE JOURNEY'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 14,
          letterSpacing: 4,
          fontWeight: FontWeight.w300,
          color: Colors.white,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : Stack(
              children: [
                MasteryPath(
                  totalXp: _totalXp,
                  currentLevel: _currentLevel,
                ),
                // The Brain Balloon (User) - Floating in the atmosphere
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 30,
                  bottom: 300 + (_consistencyScore * 8), // Vertical buoyancy
                  child: BrainBalloon(
                    brainScore: _totalXp,
                    avatarUrl: _avatarUrl,
                    label: 'YOU',
                    isUser: true,
                  ),
                ),
                // Realm 1: The Master Map at the bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: MasterMap(
                    totalXp: _totalXp,
                    currentLevel: _currentLevel,
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: _buildHeaderOverlay(),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderOverlay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF121212).withValues(alpha: 0.9),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          _buildBuoyancyIndicator(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BRAIN SCORE: $_totalXp',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_totalXp % 500) / 500,
                    backgroundColor: Colors.white12,
                    color: Colors.cyanAccent,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildLevelIndicator(),
        ],
      ),
    );
  }

  Widget _buildBuoyancyIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _consistencyScore > 0 ? Icons.keyboard_double_arrow_up_rounded : Icons.air_rounded,
          color: Colors.cyanAccent, 
          size: 20
        ),
        Text(
          _consistencyScore.toStringAsFixed(1),
          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const Text('CONSISTENCY', style: TextStyle(color: Colors.white38, fontSize: 8)),
      ],
    );
  }

  Widget _buildLevelIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('LEVEL', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        Text('$_currentLevel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
      ],
    );
  }
}
