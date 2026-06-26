import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

class UsersTableRepository {
  final SupabaseClient supabase;

  UsersTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<Map<String, dynamic>?> findById(String id) async {
    return await supabase.from('users').select().eq('id', id).maybeSingle();
  }

  Future<bool> isUserActive(String id) async {
    final user = await supabase
        .from('users')
        .select('is_active')
        .eq('id', id)
        .maybeSingle();

    return user != null && user['is_active'] == true;
  }

  Future<void> insertPatientUser(String id) async {
    final user = UserModel(id: id, role: 'patient');
    await supabase.from('users').insert(user.toMap());
  }
}
