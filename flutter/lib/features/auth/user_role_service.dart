import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole {
  free,
  premium,
  admin,
}

class UserRoleService {
  final _client = Supabase.instance.client;

  /// Returns the current user's role based on metadata or profile.
  Future<UserRole> getUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) return UserRole.free;

    // Check metadata first (easiest for now)
    final roleString = user.userMetadata?['role'] as String?;
    
    if (roleString == 'admin') return UserRole.admin;
    if (roleString == 'premium') return UserRole.premium;
    
    // Fallback: Check profiles table if we were using that
    // final profile = await _client.from('profiles').select('tier').eq('id', user.id).single();
    // ...
    
    return UserRole.free;
  }

  /// (Admin only) Promotes a user to a specific role.
  /// Note: This usually requires a secure backend function to prevent abuse,
  /// but for this prototype/MVP, we can assume the caller is an admin using RLS policies.
  Future<void> updateUserRole(String userId, UserRole role) async {
    // In a real app, use an Edge Function. 
    // Here we might try to update metadata if RLS allows, or just fail safely.
    // Ideally, we'd update a 'profiles' table column 'tier'.
    
    // final roleStr = role.name; // 'free', 'premium', 'admin'
    // await _client.from('profiles').update({'tier': roleStr}).eq('id', userId);
  }
  
  bool get isAdmin => _client.auth.currentUser?.userMetadata?['role'] == 'admin';
}
