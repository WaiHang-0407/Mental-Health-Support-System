// repositories/patient_repository.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient.dart';

class PatientRepository {
  final supabase = Supabase.instance.client;

  Future<String?> insertPatientIfNotExists(String id) async {
    try {
      final existing = await supabase
          .from('patients')
          .select('id')
          .eq('id', id)
          .maybeSingle();

      if (existing != null) {
        debugPrint("Patient already exists: $id");
        return null;
      }

      final patient = PatientModel(id: id);
      await supabase.from('patients').insert(patient.toMap());
      debugPrint("Patient inserted: $id");
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<PatientModel?> getPatientById(String id) async {
    final data = await supabase
        .from('patients')
        .select()
        .eq('id', id)
        .maybeSingle();
    return data != null ? PatientModel.fromMap(data) : null;
  }

  Future<PatientModel?> getPublicPatientById(String id) async {
    final data = await supabase
        .from('patients')
        .select('id, name, fav_animal, fav_activity, avatar_url')
        .eq('id', id)
        .maybeSingle();
    return data != null ? PatientModel.fromMap(data) : null;
  }

  Future<List<dynamic>> findNamesByIds(List ids) async {
    if (ids.isEmpty) return [];
    return await supabase
        .from('patients')
        .select('id, name, avatar_url')
        .inFilter('id', ids);
  }

  Future<Map<String, dynamic>?> findNameById(String id) async {
    return await supabase
        .from('patients')
        .select('name, avatar_url')
        .eq('id', id)
        .maybeSingle();
  }

  Future<bool> isNameEmpty(String id) async {
    final data = await findNameById(id);

    debugPrint("Patient data: $data");
    if (data == null) return true;
    final name = data['name'];
    return name == null || name.toString().trim().isEmpty;
  }

  Future<void> updateProfile(String id, Map<String, dynamic> fields) async {
    await supabase.from('patients').update(fields).eq('id', id);
  }

  Future<void> updatePersonalization(
    String id,
    Map<String, dynamic> fields,
  ) async {
    await supabase.from('patients').update(fields).eq('id', id);
  }

  Future<String?> uploadAvatar(File file, String userId) async {
    try {
      final fileName = 'avatar_$userId.jpg';
      await supabase.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
      final url = supabase.storage.from('avatars').getPublicUrl(fileName);
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('Avatar upload error: $e');
      return null;
    }
  }

  Future<void> updateAvatar(String userId, String avatarUrl) async {
    await supabase
        .from('patients')
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);
  }
}
