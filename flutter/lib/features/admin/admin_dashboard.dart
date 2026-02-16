import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _client = Supabase.instance.client;


  bool _isLoading = true;
  List<Map<String, dynamic>> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    // In production, RLS (Row Level Security) will prevent reading 'profiles'
    // unless you are an admin.
    try {
      final res = await _client
          .from('profiles')
          .select('id, display_name, created_at, user_stats(total_xp, current_streak, tier)'); // Assume tier is in user_stats or profiles
      
      // If schema differs, just grab basic profile info.
      // Assuming 'user_stats' is a foreign table join.
      
      if (mounted) {
        setState(() {
          _allUsers = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Just mock for UI dev if database denies access
          _allUsers = [
            {'id': '1', 'display_name': 'Test User', 'tier': 'Free', 'total_xp': 120},
            {'id': '2', 'display_name': 'Admin', 'tier': 'Admin', 'total_xp': 9000},
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ghost_mode_outlined), // Placeholder for Ghost Analysis
            tooltip: 'Ghost Analysis Log (Future)',
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Ghost Analysis implementation pinned for later.')),
               );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allUsers.length,
              itemBuilder: (context, index) {
                final user = _allUsers[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(user['display_name']?[0] ?? '?')),
                    title: Text(user['display_name'] ?? 'Unknown'),
                    subtitle: Text('Role: ${user['tier'] ?? 'Free'} • XP: ${user['total_xp'] ?? 0}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        // Implement manual promotion/demotion logic here
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'promote', child: Text('Promote to Premium')),
                        const PopupMenuItem(value: 'ban', child: Text('Ban User')),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (50 * index).ms).slideX();
              },
            ),
    );
  }
}
