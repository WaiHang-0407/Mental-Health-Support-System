import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_profile.dart';
import '../services/admin_auth_service.dart';

class AdminAuthController {
  AdminAuthController({AdminAuthService? adminAuthService})
      : _adminAuthService = adminAuthService ?? AdminAuthService();

  final AdminAuthService _adminAuthService;

  Stream<AuthState> get authStateChanges => _adminAuthService.authStateChanges;

  Session? get currentSession => _adminAuthService.currentSession;

  Future<AdminProfile?> currentAdminProfile() {
    return _adminAuthService.currentAdminProfile();
  }

  Future<AdminProfile> signIn({
    required String email,
    required String password,
  }) {
    return _adminAuthService.signIn(email: email, password: password);
  }

  Future<void> signOut() {
    return _adminAuthService.signOut();
  }
}
