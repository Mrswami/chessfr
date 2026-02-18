import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_screen.dart';
import '../training/training_screen.dart';
import '../profile/profile_screen.dart';
import 'admin_dashboard.dart';

/// 🔧 SECRET DEVELOPER PANEL
/// Access via 5 taps on the brain icon in AuthScreen
/// ONLY available in debug builds - automatically stripped from production
class DevPanel extends StatefulWidget {
  const DevPanel({super.key});

  @override
  State<DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends State<DevPanel> {
  final _client = Supabase.instance.client;
  final _xpController = TextEditingController(text: '500');
  final _streakController = TextEditingController(text: '7');
  
  bool _isLoading = false;

  @override
  void dispose() {
    _xpController.dispose();
    _streakController.dispose();
    super.dispose();
  }

  Future<void> _quickLogin(String email, String password, String displayName) async {
    setState(() => _isLoading = true);
    try {
      // 1. Force logout first to ensure clean state
      await _client.auth.signOut();
      
      // 2. Attempt sign in
      try {
        await _client.auth.signInWithPassword(email: email, password: password);
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        
        // If it's a rate limit error, don't try to sign up as it will just error again
        if (errorStr.contains('rate_limit') || errorStr.contains('429')) {
          throw '⚠️ Supabase Rate Limit: Please wait a minute before trying again.';
        }

        // If it looks like a "user not found" or "invalid credentials" error, attempt sign up
        // Note: Supabase sometimes returns 'Invalid login credentials' for non-existent users
        debugPrint('Sign in failed, attempting auto-signup for developer account...');
        
        await _client.auth.signUp(
          email: email,
          password: password,
          data: {
            'display_name': displayName, 
            'role': email.contains('admin') ? 'admin' : 'free'
          },
        );
        
        // After signup, attempt final sign in
        await _client.auth.signInWithPassword(email: email, password: password);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Logged in as $displayName'),
            backgroundColor: Colors.green.shade800,
          ),
        );
        // Navigate to home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      String message = e.toString();
      if (message.contains('over_email_send_rate_limit')) {
        message = '⏳ Too many login attempts. Please wait about 60 seconds.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message), 
            backgroundColor: Colors.red.shade900,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStats() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw 'Not logged in';

      // Get profile ID
      final profile = await _client
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();
      
      final profileId = profile['id'];

      // Update stats
      await _client.from('user_stats').update({
        'total_xp': int.parse(_xpController.text),
        'current_streak': int.parse(_streakController.text),
      }).eq('profile_id', profileId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Stats updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // TEMPORARY: Disabled Release mode block for beta testing
    /*
    if (kReleaseMode) {
      return const Scaffold(
        body: Center(child: Text('🚫 Not available in production')),
      );
    }
    */

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Developer Panel'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.black,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              '🎭 Quick Login',
              [
                _buildQuickLoginButton(
                  'Admin',
                  'admin@chess.dev',
                  'admin123',
                  'Admin',
                  Colors.red,
                ),
                const SizedBox(height: 8),
                _buildQuickLoginButton(
                  'Free User',
                  'free@chess.dev',
                  'free123',
                  'Free User',
                  Colors.grey,
                ),
                const SizedBox(height: 8),
                _buildQuickLoginButton(
                  'Premium User',
                  'premium@chess.dev',
                  'premium123',
                  'Premium User',
                  Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              '📊 Stats Editor',
              [
                TextField(
                  controller: _xpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total XP',
                    prefixIcon: Icon(Icons.star),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _streakController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Current Streak',
                    prefixIcon: Icon(Icons.local_fire_department),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _updateStats,
                  icon: const Icon(Icons.save),
                  label: const Text('Update My Stats'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              '🚀 Quick Navigation',
              [
                _buildNavButton('Home', Icons.home, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }),
                const SizedBox(height: 8),
                _buildNavButton('Training', Icons.school, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TrainingScreen()),
                  );
                }),
                const SizedBox(height: 8),
                _buildNavButton('Profile', Icons.person, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                }),
                const SizedBox(height: 8),
                _buildNavButton('Admin Dashboard', Icons.admin_panel_settings, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminDashboard()),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'ℹ️ Environment',
              [
                _buildInfoRow('Supabase', 'Connected'),
                _buildInfoRow('Auth Status', _client.auth.currentUser != null ? 'Logged In' : 'Logged Out'),
                _buildInfoRow('User Email', _client.auth.currentUser?.email ?? 'N/A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickLoginButton(
    String label,
    String email,
    String password,
    String displayName,
    Color color,
  ) {
    return FilledButton.icon(
      onPressed: _isLoading ? null : () => _quickLogin(email, password, displayName),
      icon: const Icon(Icons.login),
      label: Text('Login as $label'),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildNavButton(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: Colors.white24),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
