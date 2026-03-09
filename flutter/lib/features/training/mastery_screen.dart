import 'package:flutter/material.dart';
import '../training/widgets/mastery_path.dart';
import '../training/training_repository.dart';

class MasteryScreen extends StatefulWidget {
  const MasteryScreen({super.key});

  @override
  State<MasteryScreen> createState() => _MasteryScreenState();
}

class _MasteryScreenState extends State<MasteryScreen> {
  final TrainingRepository _repo = TrainingRepository();
  int _totalXp = 0;
  int _currentLevel = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final profileId = await _repo.getProfileId();
    if (profileId == null) return;
    final stats = await _repo.getUserStats(profileId);
    if (mounted && stats != null) {
      final xp = stats['total_xp'] as int? ?? 0;
      setState(() {
        _totalXp = xp;
        // Simple level calculation: Level = totalXp / 500
        _currentLevel = (xp / 500).floor();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.cyanAccent),
          ),
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
          Column(
            children: [
              const Text('LEVEL', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
              Text('$_currentLevel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }
}
