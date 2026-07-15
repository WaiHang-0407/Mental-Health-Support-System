import 'package:supabase_flutter/supabase_flutter.dart';

class UserActivityPathsTableRepository {
  final SupabaseClient supabase;

  UserActivityPathsTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<void> selectPath({
    required String userId,
    required String activityPathId,
  }) async {
    await supabase.from('user_activity_paths').upsert(
      {
        'user_id': userId,
        'activity_path_id': activityPathId,
        'last_opened_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,activity_path_id',
    );
  }

  Future<List<dynamic>> findByUser(String userId) async {
    return await supabase
        .from('user_activity_paths')
        .select(
          'activity_path_id, current_page_number, completed_page_count, last_opened_at, completed_at, is_saved, saved_at',
        )
        .eq('user_id', userId);
  }

  Future<void> updateProgress({
    required String userId,
    required String activityPathId,
    required int currentPageNumber,
    required int completedPageCount,
    required bool isCompleted,
  }) async {
    await supabase.from('user_activity_paths').upsert(
      {
        'user_id': userId,
        'activity_path_id': activityPathId,
        'current_page_number': currentPageNumber,
        'completed_page_count': completedPageCount,
        'last_opened_at': DateTime.now().toUtc().toIso8601String(),
        'completed_at': isCompleted ? DateTime.now().toUtc().toIso8601String() : null,
      },
      onConflict: 'user_id,activity_path_id',
    );
  }

  Future<void> setSaved({
    required String userId,
    required String activityPathId,
    required bool isSaved,
  }) async {
    await supabase.from('user_activity_paths').upsert(
      {
        'user_id': userId,
        'activity_path_id': activityPathId,
        'is_saved': isSaved,
        'saved_at': isSaved ? DateTime.now().toUtc().toIso8601String() : null,
      },
      onConflict: 'user_id,activity_path_id',
    );
  }
}
