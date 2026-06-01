import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole {
  free,
  premium,
  admin,
}

class UserRoleService {
  final _client = Supabase.instance.client;

  /// Returns the current user's role based on database profile or metadata.
  Future<UserRole> getUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) return UserRole.free;

    // 1. Check profiles table first (single source of truth for dynamic roles)
    try {
      final profile = await _client
          .from('profiles')
          .select('role')
          .eq('user_id', user.id)
          .maybeSingle();
      if (profile != null) {
        final dbRole = profile['role'] as String?;
        if (dbRole == 'admin') return UserRole.admin;
        if (dbRole == 'premium') return UserRole.premium;
        if (dbRole == 'free') return UserRole.free;
      }
    } catch (e) {
      debugPrint('Error getting role from profiles table: $e');
    }

    // 2. Fallback to auth metadata if database query fails or profile does not exist yet
    final roleString = user.userMetadata?['role'] as String?;
    if (roleString == 'admin') return UserRole.admin;
    if (roleString == 'premium') return UserRole.premium;
    
    return UserRole.free;
  }

  /// (Admin only) Promotes or updates a user's role in the database.
  Future<void> updateUserRole(String profileId, UserRole role) async {
    final roleStr = role.name; // 'free', 'premium', 'admin'
    await _client.from('profiles').update({'role': roleStr}).eq('id', profileId);
  }
  
  bool get isAdmin => _client.auth.currentUser?.userMetadata?['role'] == 'admin';
}
