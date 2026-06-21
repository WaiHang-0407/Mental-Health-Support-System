import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

class UsersTableRepository {
  final SupabaseClient supabase;

  UsersTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<Map<String, dynamic>?> findById(String id) async {
    return await supabase.from('users').select().eq('id', id).maybeSingle();
  }

  Future<void> insertPatientUser(String id) async {
    final user = UserModel(id: id, role: 'patient');
    await supabase.from('users').insert(user.toMap());
  }
}
