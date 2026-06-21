import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/patient_table_repository.dart';
import '../repositories/user_activity_logs_table_repository.dart';

class ProfileController {
  final PatientRepository _patientRepo = PatientRepository();
  final UserActivityLogsTableRepository _activityLogsTable =
      UserActivityLogsTableRepository();

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> saveProfile({
    required String name,
    required String gender,
    required DateTime dob,
  }) async {
    final userId = _userId;
    if (userId == null) {
      debugPrint("saveProfile: no logged in user");
      throw Exception("User not logged in");
    }
    await _patientRepo.updateProfile(userId, {
      'name': name,
      'gender': gender,
      'dob': dob.toIso8601String().split('T').first,
    });
    await _log(userId, 'profile_updated');
    debugPrint("Profile saved for $userId");
  }

  Future<void> savePersonalization({
    required List<String> conditions,
    required String favAnimal,
    required String favActivity,
  }) async {
    final userId = _userId;
    if (userId == null) {
      debugPrint("savePersonalization: no logged in user");
      throw Exception("User not logged in");
    }
    await _patientRepo.updatePersonalization(userId, {
      'condition': conditions.join(','),
      'fav_animal': favAnimal,
      'fav_activity': favActivity,
    });
    await _log(userId, 'personalization_updated');
    debugPrint("Personalization saved for $userId");
  }

  Future<void> _log(String userId, String action) async {
    await _activityLogsTable.insert(
      patientId: userId,
      action: action,
      targetType: 'profile',
    );
  }
}
