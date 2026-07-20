import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/database_tables.dart';
import '../models/daily_activity.dart';

class DailyActivitiesRepository {
  DailyActivitiesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<DailyActivity>> fetchDailyActivities() async {
    final rows = await _client
        .from(DatabaseTables.dailyActivities)
        .select()
        .order('created_at', ascending: false);

    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        DailyActivity.fromJson(row),
    ];
  }

  Future<void> createDailyActivity(DailyActivity activity) {
    return _client
        .from(DatabaseTables.dailyActivities)
        .insert(activity.toCreateJson());
  }

  Future<void> updateDailyActivity(DailyActivity activity) {
    final activityId = activity.id;
    if (activityId == null) {
      throw ArgumentError('Daily activity id is required.');
    }

    return _client
        .from(DatabaseTables.dailyActivities)
        .update(activity.toUpdateJson())
        .eq('id', activityId);
  }

  Future<void> setActive({
    required String activityId,
    required bool isActive,
  }) {
    return _client
        .from(DatabaseTables.dailyActivities)
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', activityId);
  }
}
