import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/database_tables.dart';
import '../models/admin_profile.dart';

class AdminAuthRepository {
  AdminAuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  Future<AdminProfile?> currentAdminProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    return _fetchActiveAdminProfile(user);
  }

  Future<AdminProfile> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;

    if (user == null) {
      throw const AuthException('Invalid email or password.');
    }

    final profile = await _fetchActiveAdminProfile(user);
    if (profile == null) {
      await _client.auth.signOut();
      throw const AuthException('This account is not allowed to access admin.');
    }

    await _recordLogin(profile);
    return profile;
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<AdminProfile?> _fetchActiveAdminProfile(User user) async {
    final data = await _client
        .from(DatabaseTables.users)
        .select('id, role, is_active')
        .eq('id', user.id)
        .eq('role', 'admin')
        .eq('is_active', true)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return AdminProfile.fromJson({
      ...data,
      'email': user.email ?? '',
    });
  }

  Future<void> _recordLogin(AdminProfile profile) async {
    try {
      await _client.from(DatabaseTables.adminLoginLogs).insert({
        'admin_id': profile.id,
        'email': profile.email,
        'event': 'signed_in',
      });
    } catch (_) {
      // Audit logging should never block a valid admin from signing in.
    }
  }
}
