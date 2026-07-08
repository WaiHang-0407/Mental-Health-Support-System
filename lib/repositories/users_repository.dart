import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/database_tables.dart';
import '../models/admin_user.dart';

class UsersRepository {
  UsersRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<AdminUser>> fetchUsers() async {
    final users = await _client
        .from(DatabaseTables.users)
        .select('id, role, is_active, created_at')
        .order('created_at', ascending: false);

    final userRows = users.cast<Map<String, dynamic>>();
    if (userRows.isEmpty) {
      return const [];
    }

    final userIds = userRows.map((row) => row['id'] as String).toList();
    final patients = await _client
        .from(DatabaseTables.patients)
        .select('id, name, gender, phoneno, avatar_url')
        .inFilter('id', userIds);

    final patientRows = patients.cast<Map<String, dynamic>>();
    final patientsById = {
      for (final patient in patientRows) patient['id'] as String: patient,
    };

    final subscriptions = await _client
        .from(DatabaseTables.subscriptions)
        .select('patient_id, is_active, expires_at')
        .inFilter('patient_id', userIds);

    final subscriptionRows = subscriptions.cast<Map<String, dynamic>>();
    final subscriptionsByPatientId = {
      for (final subscription in subscriptionRows)
        subscription['patient_id'] as String: subscription,
    };

    return [
      for (final user in userRows)
        AdminUser.fromRows(
          user: user,
          patient: patientsById[user['id'] as String],
          subscription: subscriptionsByPatientId[user['id'] as String],
        ),
    ];
  }

  Future<void> updateUserActiveStatus({
    required String userId,
    required bool isActive,
  }) {
    return _client
        .from(DatabaseTables.users)
        .update({'is_active': isActive})
        .eq('id', userId);
  }
}
