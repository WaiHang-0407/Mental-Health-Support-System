import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity_path.dart';
import 'activity_path_page_images_table_repository.dart';
import 'activity_path_pages_table_repository.dart';
import 'activity_paths_table_repository.dart';
import 'user_activity_logs_table_repository.dart';
import 'user_activity_paths_table_repository.dart';

class ActivityPathRepository {
  final SupabaseClient supabase;
  final ActivityPathsTableRepository _pathsTable;
  final ActivityPathPagesTableRepository _pagesTable;
  final ActivityPathPageImagesTableRepository _imagesTable;
  final UserActivityPathsTableRepository _userPathsTable;
  final UserActivityLogsTableRepository _activityLogsTable;

  ActivityPathRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client,
      _pathsTable = ActivityPathsTableRepository(supabase: supabase),
      _pagesTable = ActivityPathPagesTableRepository(supabase: supabase),
      _imagesTable = ActivityPathPageImagesTableRepository(supabase: supabase),
      _userPathsTable = UserActivityPathsTableRepository(supabase: supabase),
      _activityLogsTable = UserActivityLogsTableRepository(supabase: supabase);

  String get _uid => supabase.auth.currentUser!.id;

  Future<List<ActivityPath>> getActivePaths() async {
    final pathRows = await _pathsTable.getActivePaths();
    return _buildPaths(pathRows);
  }

  Future<ActivityPath?> getActivePathById(String activityPathId) async {
    final pathRow = await _pathsTable.getActivePathById(activityPathId);
    if (pathRow == null) return null;

    final paths = await _buildPaths([pathRow]);
    return paths.isEmpty ? null : paths.first;
  }

  Future<List<ActivityPath>> _buildPaths(List<dynamic> pathRows) async {
    final pathIds = pathRows.map((row) => row['id'] as String).toList();
    final pageRows = await _pagesTable.getPagesForPaths(pathIds);
    final pageIds = pageRows.map((row) => row['id'] as String).toList();
    final imageRows = await _imagesTable.getImagesForPages(pageIds);

    final imagesByPageId = <String, List<ActivityPathImage>>{};
    for (final row in imageRows) {
      final image = ActivityPathImage.fromMap(Map<String, dynamic>.from(row));
      imagesByPageId.putIfAbsent(image.pageId, () => []).add(image);
    }

    final pagesByPathId = <String, List<ActivityPathPage>>{};
    for (final row in pageRows) {
      final pageMap = Map<String, dynamic>.from(row);
      final page = ActivityPathPage.fromMap(
        pageMap,
        images: imagesByPageId[pageMap['id']] ?? const [],
      );
      pagesByPathId.putIfAbsent(page.activityPathId, () => []).add(page);
    }

    final progressRows = await _userPathsTable.findByUser(_uid);
    final progressByPathId = {
      for (final row in progressRows.cast<Map<String, dynamic>>())
        row['activity_path_id'] as String: ActivityPathProgress.fromMap(row),
    };

    return pathRows.map((row) {
      final pathMap = Map<String, dynamic>.from(row);
      return ActivityPath.fromMap(
        pathMap,
        pages: pagesByPathId[pathMap['id']] ?? const [],
        progress: progressByPathId[pathMap['id']],
      );
    }).toList();
  }

  Future<List<ActivityPath>> getSelectedPaths() async {
    return (await getActivePaths()).where((path) => path.isSelected).toList();
  }

  Future<void> selectPath(String activityPathId) async {
    await _userPathsTable.selectPath(
      userId: _uid,
      activityPathId: activityPathId,
    );
    await _activityLogsTable.insert(
      patientId: _uid,
      action: 'activity_path_selected',
      targetType: 'activity_path',
      targetId: activityPathId,
    );
  }

  Future<void> updateProgress({
    required String activityPathId,
    required int currentPageNumber,
    required int completedPageCount,
    required bool isCompleted,
  }) {
    return _userPathsTable.updateProgress(
      userId: _uid,
      activityPathId: activityPathId,
      currentPageNumber: currentPageNumber,
      completedPageCount: completedPageCount,
      isCompleted: isCompleted,
    );
  }

  Future<void> setSaved({
    required String activityPathId,
    required bool isSaved,
  }) {
    return _userPathsTable.setSaved(
      userId: _uid,
      activityPathId: activityPathId,
      isSaved: isSaved,
    );
  }
}
