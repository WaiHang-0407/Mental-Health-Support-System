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
    final registrations = await _activityRegistrationsTable
        .findActiveRegistrations(_uid, activityIds);

    final registeredIds = registrations.map((r) => r['activity_id']).toSet();

    return data.map((a) {
      final map = <String, dynamic>{
        ...Map<String, dynamic>.from(a),
        'registered_count':
            (a['activity_registrations'] as List?)?.first?['count'] ?? 0,
      };
      return CommunityActivity.fromMap(
        map,
        isRegistered: registeredIds.contains(a['id']),
      );
    }).toList();
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
