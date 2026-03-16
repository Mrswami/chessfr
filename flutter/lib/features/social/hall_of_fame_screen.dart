import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HallOfFameScreen extends StatefulWidget {
  const HallOfFameScreen({super.key});

  @override
  State<HallOfFameScreen> createState() => _HallOfFameScreenState();
}

class _HallOfFameScreenState extends State<HallOfFameScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _pinnedEntries = [];
  Set<String> _myUpvotes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    try {
      final user = _supabase.auth.currentUser;

      final entries = await _supabase
          .from('hall_of_fame')
          .select()
          .eq('is_approved', true)
          .order('upvotes', ascending: false)
          .limit(50);

      Set<String> myUpvotes = {};
      if (user != null) {
        final upvotes = await _supabase
            .from('hall_of_fame_upvotes')
            .select('hof_id')
            .eq('user_id', user.id);
        myUpvotes = {for (final u in upvotes) u['hof_id'] as String};
      }

      final all = List<Map<String, dynamic>>.from(entries);
      final pinned = all.where((e) => e['is_pinned'] == true).toList();

      if (mounted) {
        setState(() {
          _entries = all;
          _pinnedEntries = pinned;
          _myUpvotes = myUpvotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('HoF load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _upvote(String hofId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    HapticFeedback.lightImpact();

    if (_myUpvotes.contains(hofId)) return; // already voted

    try {
      await _supabase.from('hall_of_fame_upvotes').insert({
        'user_id': user.id,
        'hof_id': hofId,
      });
      await _supabase.rpc('increment_hof_upvote', params: {'hof_id': hofId});
      setState(() => _myUpvotes.add(hofId));
      await _loadEntries();
    } catch (e) {
      debugPrint('Upvote error: $e');
    }
  }

  Future<void> _showSubmitDialog() async {
    final captionController = TextEditingController();
    final displayNameController = TextEditingController();
    final fenController = TextEditingController();
    final moveController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🏆 Nominate a Brilliant Move',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Submissions must pass our Brilliant Move validator.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
            const SizedBox(height: 20),
            _buildField(displayNameController, 'Featured Player (e.g. Magnus Carlsen)'),
            const SizedBox(height: 12),
            _buildField(fenController, 'FEN Position (before the move)'),
            const SizedBox(height: 12),
            _buildField(moveController, 'The Move (e.g. Rxf7)'),
            const SizedBox(height: 12),
            _buildField(captionController, 'Caption (max 280 chars)', maxLines: 3),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                _submitNomination(
                  featuredName: displayNameController.text.trim(),
                  fen: fenController.text.trim(),
                  moveSan: moveController.text.trim(),
                  caption: captionController.text.trim(),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade700),
              child: const Text('SUBMIT FOR REVIEW', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String hint, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
    );
  }

  Future<void> _submitNomination({
    required String featuredName,
    required String fen,
    required String moveSan,
    required String caption,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (featuredName.isEmpty || fen.isEmpty || moveSan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await _supabase.from('hall_of_fame').insert({
        'nominator_user_id': user.id,
        'featured_display_name': featuredName,
        'fen': fen,
        'move_san': moveSan,
        'caption': caption.isEmpty ? null : caption,
        'is_approved': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Submitted! Our team will review your nomination.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            const Text(
              'Hall of Fame',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: '🔥 TOP MOVES'),
            Tab(text: '👑 PINNED'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitDialog,
        backgroundColor: Colors.amber.shade700,
        icon: const Icon(Icons.star_rounded, color: Colors.black),
        label: const Text('NOMINATE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ).animate().slideY(begin: 1, end: 0, delay: 300.ms),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEntryList(_entries),
                _buildEntryList(_pinnedEntries, showPin: true),
              ],
            ),
    );
  }

  Widget _buildEntryList(List<Map<String, dynamic>> entries, {bool showPin = false}) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(showPin ? '👑' : '⭐', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              showPin ? 'No pinned moves yet.\nTop 3 each week get crowned!' : 'Be the first to nominate\na brilliant move!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildEntryCard(entry, index, showPin: showPin);
      },
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry, int index, {bool showPin = false}) {
    final hofId = entry['id'] as String;
    final hasVoted = _myUpvotes.contains(hofId);
    final upvotes = entry['upvotes'] as int? ?? 0;
    final isPinned = entry['is_pinned'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPinned
              ? [const Color(0xFF2D1B00), const Color(0xFF1A1A00)]
              : [Colors.white.withValues(alpha: 0.04), Colors.white.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPinned ? Colors.amber.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isPinned)
                  const Text('👑 ', style: TextStyle(fontSize: 16)),
                Text(
                  entry['featured_display_name'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '⭐ ${entry['move_san'] ?? '?'}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (entry['caption'] != null && (entry['caption'] as String).isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '"${entry['caption']}"',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                GestureDetector(
                  onTap: hasVoted ? null : () => _upvote(hofId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: hasVoted
                          ? Colors.amber.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasVoted
                            ? Colors.amber.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasVoted ? Icons.star_rounded : Icons.star_border_rounded,
                          color: hasVoted ? Colors.amber : Colors.white38,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$upvotes',
                          style: TextStyle(
                            color: hasVoted ? Colors.amber : Colors.white38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().scale(delay: (index * 50).ms, curve: Curves.elasticOut),
                const Spacer(),
                Text(
                  '#${index + 1}',
                  style: TextStyle(
                    color: index == 0
                        ? Colors.amber
                        : index == 1
                            ? Colors.grey.shade400
                            : index == 2
                                ? Colors.orange.shade300
                                : Colors.white24,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.05, end: 0);
  }
}
