import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/user_role_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _client = Supabase.instance.client;
  final _roleService = UserRoleService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final res = await _client
          .from('profiles')
          .select('id, display_name, role, created_at, user_stats(total_aura, current_streak)');
      
      if (mounted) {
        setState(() {
          _allUsers = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Admin query failed, falling back to mock: $e');
      if (mounted) {
        setState(() {
          _allUsers = [
            {
              'id': 'mock-1',
              'display_name': 'AmateurSwami',
              'role': 'free',
              'user_stats': {'total_aura': 1200, 'current_streak': 5}
            },
            {
              'id': 'mock-2',
              'display_name': 'MrSwami (Admin)',
              'role': 'admin',
              'user_stats': {'total_aura': 9000, 'current_streak': 30}
            },
          ];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateRole(String profileId, UserRole role) async {
    setState(() => _isLoading = true);
    try {
      await _roleService.updateUserRole(profileId, role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User role updated to ${role.name}!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e'), backgroundColor: Colors.red),
        );
      }
    }
    _loadAdminData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadAdminData();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allUsers.isEmpty
              ? const Center(child: Text('No users found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allUsers.length,
                  itemBuilder: (context, index) {
                    final user = _allUsers[index];
                    final stats = user['user_stats'];
                    int aura = 0;
                    int streak = 0;
                    
                    if (stats is Map) {
                      aura = stats['total_aura'] ?? 0;
                      streak = stats['current_streak'] ?? 0;
                    } else if (stats is List && stats.isNotEmpty) {
                      final first = stats.first;
                      if (first is Map) {
                        aura = first['total_aura'] ?? 0;
                        streak = first['current_streak'] ?? 0;
                      }
                    }

                    final String role = user['role'] ?? 'free';

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(user['display_name']?[0]?.toUpperCase() ?? '?'),
                        ),
                        title: Text(user['display_name'] ?? 'Unknown'),
                        subtitle: Text(
                          'Role: ${role.toUpperCase()} • Aura: $aura • Streak: $streak 🔥',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'free') {
                              _updateRole(user['id'], UserRole.free);
                            } else if (value == 'premium') {
                              _updateRole(user['id'], UserRole.premium);
                            } else if (value == 'admin') {
                              _updateRole(user['id'], UserRole.admin);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'free',
                              enabled: role != 'free',
                              child: const Text('Set to Free'),
                            ),
                            PopupMenuItem(
                              value: 'premium',
                              enabled: role != 'premium',
                              child: const Text('Set to Premium'),
                            ),
                            PopupMenuItem(
                              value: 'admin',
                              enabled: role != 'admin',
                              child: const Text('Set to Admin'),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (50 * index).ms).slideX();
                  },
                ),
    );
  }
}
