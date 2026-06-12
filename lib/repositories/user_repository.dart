// repositories/user_repository.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

class UserRepository {
  final supabase = Supabase.instance.client;

  // Returns null on success, error string on failure
  Future<String?> insertUserIfNotExists(String id) async {
    try {
      // Check first
      final existing = await supabase
          .from('users')
          .select('id')
          .eq('id', id)
          .maybeSingle();

      if (existing != null) {
        debugPrint("User already exists: $id");
        return null; // already there, no error
      }

      await supabase.from('users').insert({'id': id, 'role': 'patient'});
      debugPrint("User inserted: $id");
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<UserModel?> getUserById(String id) async {
    final data = await supabase
        .from('users')
        .select()
        .eq('id', id)
        .maybeSingle();
    return data != null ? UserModel.fromMap(data) : null;
  }
}