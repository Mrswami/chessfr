import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../training/training_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _repo = TrainingRepository();
  final GlobalKey _boundaryKey = GlobalKey();
  
  bool _isLoading = true;
  bool _isSharing = false;
  bool _isDankFishMode = false;
  
  // User stats
  int _totalXp = 0;
  int _currentStreak = 0;
  String _tier = 'Free';
  
  // Cognitive profile percentages
  double _connectivityPct = 33.0;
  double _responsePct = 33.0;
  double _influencePct = 34.0;
  
  // Face Avatar
  String? _avatarUrl;
  
  // Avatar customization
  String _selectedSantaVariant = 'classic'; // classic, jolly, cool, sleepy
  String _selectedBackground = 'dark'; // dark, blue, green, purple

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Safety timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Profile taking a while... Try refreshing.')),
        );
      }
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('No current user found during profile load');
        setState(() => _isLoading = false);
        return;
      }
      final userId = user.id;

      // 1. Load profile preferences first using user_id
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (profile == null) {
        debugPrint('Profile not found for user $userId');
        setState(() => _isLoading = false);
        return;
      }

      // 2. Load user stats using the profile's ID
      final profileId = profile['id'];
      final stats = await _supabase
          .from('user_stats')
          .select()
          .eq('profile_id', profileId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (stats != null) {
            _totalXp = stats['total_xp'] ?? 0;
            _currentStreak = stats['current_streak'] ?? 0;
            _tier = stats['tier'] ?? 'Free';
          }
          
          // Load cognitive profile
          final cognitiveProfile = profile['cognitive_profile'] as Map<String, dynamic>? ?? {};
          _connectivityPct = (cognitiveProfile['connectivity_weight'] ?? 0.33) * 100;
          _responsePct = (cognitiveProfile['response_weight'] ?? 0.33) * 100;
          _influencePct = (cognitiveProfile['influence_weight'] ?? 0.34) * 100;
          
          // Load avatar preferences
          _isDankFishMode = profile['engine_mode'] == 'dankfish';
          _selectedSantaVariant = profile['avatar_variant'] ?? 'classic';
          _selectedBackground = profile['avatar_background'] ?? 'dark';
          _avatarUrl = profile['avatar_url'];
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveEngineMode(bool isDankFish) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('profiles')
          .update({'engine_mode': isDankFish ? 'dankfish' : 'stockfish'})
          .eq('user_id', userId);

      setState(() => _isDankFishMode = isDankFish);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDankFish 
                ? '🎅 DankFish Mode Activated!' 
                : '🐟 Stockfish Mode Activated!'),
            backgroundColor: isDankFish ? Colors.red.shade700 : Colors.cyan.shade700,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving engine mode: $e');
    }
  }

  Future<void> _saveAvatarCustomization() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('profiles')
          .update({
            'avatar_variant': _selectedSantaVariant,
            'avatar_background': _selectedBackground,
          })
          .eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ Avatar updated!')),
        );
      }
    } catch (e) {
      debugPrint('Error saving avatar: $e');
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image == null) return;
      
      setState(() => _isLoading = true);
      final url = await _repo.uploadAvatar(File(image.path));
      
      if (mounted) {
        setState(() {
          _avatarUrl = url;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🤳 Face Uploaded Comically!')),
        );
      }
    } catch (e) {
      debugPrint('Error uploading face: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _shareProfile() async {
    setState(() => _isSharing = true);
    
    try {
      // Small delay to ensure any animations finish
      await Future.delayed(const Duration(milliseconds: 500));
      
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      
      final pngBytes = byteData.buffer.asUint8List();
      
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/chess_xl_profile.png').create();
      await file.writeAsBytes(pngBytes);
      
      final mode = _isDankFishMode ? 'DankFish 🎅' : 'Stockfish 🐟';
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my $mode profile in Chess FR! I have $_totalXp Aura and a $_currentStreak day streak. 🔥',
      );
    } catch (e) {
      debugPrint('Error sharing profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _isSharing 
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share Profile',
                onPressed: _shareProfile,
              ),
        ],
      ),
      body: _isLoading
          ? Center(child: _buildPulsingSanta())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Everything inside this RepaintBoundary will be in the screenshot
                  RepaintBoundary(
                    key: _boundaryKey,
                    child: Container(
                      color: const Color(0xFF0F0F0F), // Background for the snapshot
                      child: Column(
                        children: [
                          // Avatar Display Card
                          _buildAvatarCard(),
                          const SizedBox(height: 16),
                          
                          // Stats Cards (Inline for shareability)
                          _buildStatsSection(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Engine Mode Toggle
                  _buildEngineModeToggle(),
                  const SizedBox(height: 16),
                  
                  // Cognitive Profile
                  _buildCognitiveProfile(),
                  const SizedBox(height: 16),
                  
                  // Avatar Customization
                  _buildAvatarCustomization(),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getBackgroundGradient(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Face or Santa Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              if (_avatarUrl != null)
                ClipOval(
                  child: Image.network(
                    _avatarUrl!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                )
              else
                Text(
                  _getSantaEmoji(),
                  style: const TextStyle(fontSize: 120),
                ),
              
              // Comical Upload Button
              GestureDetector(
                onTap: _pickAndUploadAvatar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.add_a_photo_rounded, color: Colors.black, size: 20),
                ),
              ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
            ],
          ),
          const SizedBox(height: 16),
          
          // Username
          Text(
            _supabase.auth.currentUser?.email?.split('@').first ?? 'Player',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Tier Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _getTierColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _tier.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(delay: 100.ms);
  }

  Widget _buildEngineModeToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENGINE MODE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildEngineModeButton(
                  isSelected: !_isDankFishMode,
                  icon: '🐟',
                  title: 'Stockfish',
                  subtitle: 'Pure engine power',
                  onTap: () => _saveEngineMode(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEngineModeButton(
                  isSelected: _isDankFishMode,
                  icon: '🎅',
                  title: 'DankFish',
                  subtitle: 'Your style, optimized',
                  onTap: () => _saveEngineMode(true),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildEngineModeButton({
    required bool isSelected,
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (title == 'DankFish' ? Colors.red.shade900 : Colors.cyan.shade900)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? (title == 'DankFish' ? Colors.red : Colors.cyan)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Aura', _totalXp.toString(), Icons.stars, Colors.amber)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Streak', '$_currentStreak 🔥', Icons.local_fire_department, Colors.orange)),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCognitiveProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COGNITIVE PROFILE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildProfileBar('Connectivity', _connectivityPct, Colors.cyan),
          const SizedBox(height: 12),
          _buildProfileBar('Response', _responsePct, Colors.amber),
          const SizedBox(height: 12),
          _buildProfileBar('Influence', _influencePct, Colors.purple),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildProfileBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarCustomization() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CUSTOMIZE AVATAR',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          
          // Santa Variants
          const Text('Santa Style', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAvatarOption('classic', '🎅'),
              _buildAvatarOption('jolly', '😄🎅'),
              _buildAvatarOption('cool', '😎🎅'),
              _buildAvatarOption('sleepy', '😴🎅'),
              _buildAvatarOption('king', '🤴🎅'),
              _buildAvatarOption('robot', '🤖🎅'),
              _buildAvatarOption('space', '🚀🎅'),
              _buildAvatarOption('ninja', '🥷🎅'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Background Colors
          const Text('Background', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorOption('dark', Colors.grey.shade900),
              _buildColorOption('blue', Colors.blue.shade700),
              _buildColorOption('green', Colors.green.shade700),
              _buildColorOption('purple', Colors.purple.shade700),
              _buildColorOption('gold', Colors.amber.shade800),
              _buildColorOption('fire', Colors.red.shade700),
              _buildColorOption('forest', Colors.teal.shade800),
              _buildColorOption('arctic', Colors.cyan.shade300),
            ],
          ),
          const SizedBox(height: 16),
          
          ElevatedButton(
            onPressed: _saveAvatarCustomization,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SAVE AVATAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildAvatarOption(String variant, String emoji) {
    final isSelected = _selectedSantaVariant == variant;
    return GestureDetector(
      onTap: () => setState(() => _selectedSantaVariant = variant),
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade900 : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 32)),
      ),
    );
  }

  Widget _buildColorOption(String colorName, Color color) {
    final isSelected = _selectedBackground == colorName;
    return GestureDetector(
      onTap: () => setState(() => _selectedBackground = colorName),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  String _getSantaEmoji() {
    switch (_selectedSantaVariant) {
      case 'jolly':
        return '😄🎅';
      case 'cool':
        return '😎🎅';
      case 'sleepy':
        return '😴🎅';
      case 'king':
        return '🤴🎅';
      case 'robot':
        return '🤖🎅';
      case 'space':
        return '🚀🎅';
      case 'ninja':
        return '🥷🎅';
      default:
        return '🎅';
    }
  }

  List<Color> _getBackgroundGradient() {
    switch (_selectedBackground) {
      case 'blue':
        return [Colors.blue.shade900, Colors.blue.shade700];
      case 'green':
        return [Colors.green.shade900, Colors.green.shade700];
      case 'purple':
        return [Colors.purple.shade900, Colors.purple.shade700];
      case 'gold':
        return [const Color(0xFFB8860B), const Color(0xFFFFD700)];
      case 'fire':
        return [Colors.red.shade900, Colors.orange.shade800];
      case 'forest':
        return [const Color(0xFF003300), const Color(0xFF006600)];
      case 'arctic':
        return [Colors.cyan.shade900, Colors.cyan.shade100];
      default:
        return [Colors.grey.shade900, Colors.grey.shade800];
    }
  }

  Color _getTierColor() {
    switch (_tier.toLowerCase()) {
      case 'premium':
        return Colors.amber.shade700;
      case 'admin':
        return Colors.red.shade700;
      default:
        return Colors.cyan.shade700;
    }
  }

  Widget _buildPulsingSanta() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '🎅',
          style: TextStyle(fontSize: 80),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.2, 1.2),
              duration: 800.ms,
              curve: Curves.easeInOut,
            )
            .shimmer(delay: 400.ms, duration: 1200.ms, color: Colors.white30),
        const SizedBox(height: 24),
        const Text(
          'Summoning your profile...',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.1,
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }
}
