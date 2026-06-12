import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<void> signInWithGoogle() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://login-callback',
    );
  }

  Future<void> signInWithFacebook() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'io.supabase.flutter://login-callback',
    );
  }

  Future<User?> getCurrentUser() async {
    return supabase.auth.currentUser;
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
