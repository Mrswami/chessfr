import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../training/training_repository.dart';
import '../training/training_screen.dart';
import '../analysis/import_view.dart';
import '../analysis/game_library_screen.dart';
import '../auth/user_role_service.dart';
import '../admin/admin_dashboard.dart';
import '../projection/ui/camera_recognition_screen.dart';
import '../projection/ui/board_connection_screen.dart';
import '../profile/profile_screen.dart';
import '../social/social_hub_screen.dart';
import '../training/mastery_screen.dart';
import '../social/hall_of_fame_screen.dart';
import '../analysis/brilliant_tracker_widget.dart';
import 'concierge_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TrainingRepository _repo = TrainingRepository();
  final UserRoleService _roleService = UserRoleService();
  
  int _streak = 0;
  int _aura = 0;
  UserRole _role = UserRole.free;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = await _roleService.getUserRole();
    if (mounted) setState(() => _role = role);
  }

  Future<void> _loadStats() async {
    final profileId = await _repo.getProfileId();
    if (profileId == null) return;
    final stats = await _repo.getUserStats(profileId);
    if (mounted && stats != null) {
      setState(() {
        _streak = stats['current_streak'] as int? ?? 0;
        _aura = stats['total_aura'] as int? ?? 0;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['display_name'] ?? 'Player';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $name',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatChip(context, Icons.local_fire_department_rounded, '$_streak', 'Streak'),
                            const SizedBox(width: 12),
                            _buildStatChip(context, Icons.star_rounded, '$_aura', 'Aura'),
                          ],
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      onPressed: () => _signOut(context),
                    ).animate().fadeIn(delay: 50.ms),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: const ConciergeCardWidget(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: const BrilliantTrackerWidget(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildActionTile(
                    context,
                    title: 'Start Training',
                    subtitle: 'Pattern-aligned puzzles ready.',
                    icon: Icons.play_circle_fill_rounded,
                    color: const Color(0xFF0D9488),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TrainingScreen()),
                      );
                      if (mounted) _loadStats();
                    },
                    delay: 150,
                  ),
                  const SizedBox(height: 14),
                  _buildActionTile(
                    context,
                    title: 'Mastery Journey',
                    subtitle: 'Visualize your neural progression.',
                    icon: Icons.map_rounded,
                    color: Colors.cyanAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MasteryScreen()),
                      );
                    },
                    delay: 175,
                  ),
                  const SizedBox(height: 14),
                  _buildActionTile(
                    context,
                    title: 'My Profile',
                    subtitle: 'Customize your DankFish avatar.',
                    icon: Icons.person_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    delay: 200,
                  ),
                  const SizedBox(height: 14),
                  _buildActionTile(
                    context,
                    title: 'Analyze Game',
                    subtitle: 'Find swing spots in your games.',
                    icon: Icons.auto_graph_rounded,
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ImportView()),
                      );
                    },
                    delay: 250,
                  ),
                  const SizedBox(height: 14),
                  _buildActionTile(
                    context,
                    title: 'Hall of Fame',
                    subtitle: 'Community\'s greatest brilliant moves.',
                    icon: Icons.emoji_events_rounded,
                    color: Colors.amber,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HallOfFameScreen()),
                      );
                    },
                    delay: 260,
                  ),
                  const SizedBox(height: 14),
                  _buildActionTile(
                    context,
                    title: 'Community Hub',
                    subtitle: 'Pulse of the community.',
                    icon: Icons.diversity_3_rounded,
                    color: Colors.cyanAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SocialHubScreen()),
                      );
                    },
                    delay: 275,
                  ),
                  const SizedBox(height: 14),
                  _buildActionTile(
                    context,
                    title: 'Game Archive',
                    subtitle: 'View your recorded history.',
                    icon: Icons.inventory_2_rounded,
                    color: Colors.pinkAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GameLibraryScreen()),
                      );
                    },
                    delay: 260,
                  ),
                  const SizedBox(height: 14),
                  _buildActionTile(
                    context,
                    title: 'Chess Vision',
                    subtitle: 'Scan and analyze real boards.',
                    icon: Icons.camera_alt_rounded,
                    color: Colors.cyan,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CameraRecognitionScreen()),
                      );
                    },
                    delay: 275,
                  ),
                  const SizedBox(height: 14),
                  _buildActionTile(
                    context,
                    title: 'Connect Board',
                    subtitle: 'Link your ChessUp hardware.',
                    icon: Icons.bluetooth_rounded,
                    color: Colors.indigoAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BoardConnectionScreen()),
                      );
                    },
                    delay: 290,
                  ),
                  if (_role == UserRole.admin) ...[
                    const SizedBox(height: 14),
                    _buildActionTile(
                      context,
                      title: 'Admin Dashboard',
                      subtitle: 'Manage users and content.',
                      icon: Icons.admin_panel_settings_rounded,
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminDashboard()),
                        );
                      },
                      delay: 300,
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}
