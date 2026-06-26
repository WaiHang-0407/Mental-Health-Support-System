import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_profile.dart';
import '../repositories/admin_auth_repository.dart';

class AdminAuthService {
  AdminAuthService({AdminAuthRepository? adminAuthRepository})
      : _adminAuthRepository = adminAuthRepository ?? AdminAuthRepository();

  final AdminAuthRepository _adminAuthRepository;

  Stream<AuthState> get authStateChanges => _adminAuthRepository.authStateChanges;

  Session? get currentSession => _adminAuthRepository.currentSession;

  Future<AdminProfile?> currentAdminProfile() {
    return _adminAuthRepository.currentAdminProfile();
  }

  Future<AdminProfile> signIn({
    required String email,
    required String password,
  }) {
    return _adminAuthRepository.signIn(email: email, password: password);
  }

  Future<void> signOut() {
    return _adminAuthRepository.signOut();
  }
}
