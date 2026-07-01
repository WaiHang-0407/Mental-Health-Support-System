import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRoleRepository {
  final supabase = Supabase.instance.client;

  Future<String?> getCurrentUserRole() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final data = await supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      return data?['role']?.toString();
    } catch (e) {
      debugPrint('Get user role error: $e');
      return null;
    }
  }

  Future<bool> canAccessListenerMode() async {
    final role = await getCurrentUserRole();

    return role == 'listener' || role == 'patient_listener';
  }
}
