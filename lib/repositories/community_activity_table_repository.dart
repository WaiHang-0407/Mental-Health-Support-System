// repositories/activity_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_activity.dart';
import 'activities_table_repository.dart';
import 'activity_registrations_table_repository.dart';
import 'user_activity_logs_table_repository.dart';

class CommunityActivityRepository {
  final supabase = Supabase.instance.client;
  final _activitiesTable = ActivitiesTableRepository();
  final _activityRegistrationsTable = ActivityRegistrationsTableRepository();
  final _activityLogsTable = UserActivityLogsTableRepository();

  String get _uid => supabase.auth.currentUser!.id;

  Future<List<CommunityActivity>> getActivities() async {
    final data = await _activitiesTable.getVisibleActivities();

    final activityIds = data.map((a) => a['id']).toList();
    List<dynamic> registrations = [];
    List<dynamic> allRegistrations = [];

    try {
      registrations = await _activityRegistrationsTable.findActiveRegistrations(
        _uid,
        activityIds,
      );
    } catch (_) {
      registrations = [];
    }

    try {
      allRegistrations = await _activityRegistrationsTable
          .findActiveRegistrationsForActivities(activityIds);
    } catch (_) {
      allRegistrations = [];
    }

    final registeredIds = registrations.map((r) => r['activity_id']).toSet();
    final registrationCounts = <String, int>{};
    for (final row in allRegistrations) {
      final activityId = row['activity_id'] as String?;
      if (activityId == null) continue;
      registrationCounts[activityId] = (registrationCounts[activityId] ?? 0) + 1;
    }

    return data.map((a) {
      final map = <String, dynamic>{
        ...Map<String, dynamic>.from(a),
        'registered_count': registrationCounts[a['id']] ?? 0,
      };
      return CommunityActivity.fromMap(
        map,
        isRegistered: registeredIds.contains(a['id']),
      );
    }).toList();
  }

  Future<CommunityActivity?> getActivityById(String activityId) async {
    final row = await _activitiesTable.getVisibleActivityById(activityId);
    if (row == null) return null;

    bool isRegistered = false;
    var registeredCount = 0;

    try {
      final registrations = await _activityRegistrationsTable
          .findActiveRegistrations(_uid, [activityId]);
      isRegistered = registrations.any((r) => r['activity_id'] == activityId);
    } catch (_) {
      isRegistered = false;
    }

    try {
      final allRegistrations = await _activityRegistrationsTable
          .findActiveRegistrationsForActivities([activityId]);
      registeredCount = allRegistrations
          .where((r) => r['activity_id'] == activityId)
          .length;
    } catch (_) {
      registeredCount = 0;
    }

    return CommunityActivity.fromMap(
      {...row, 'registered_count': registeredCount},
      isRegistered: isRegistered,
    );
  }

  Future<void> register(String activityId) async {
    await _activityRegistrationsTable.register(activityId, _uid);
    await _log('activity_registered', targetId: activityId);
  }

  Future<void> cancelRegistration(String activityId) async {
    await _activityRegistrationsTable.cancel(activityId, _uid);
    await _log('activity_cancelled', targetId: activityId);
  }

  Future<void> _log(String action, {String? targetId}) async {
    await _activityLogsTable.insert(
      patientId: _uid,
      action: action,
      targetType: 'activity',
      targetId: targetId,
    );
  }
}
