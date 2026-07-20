import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/database_tables.dart';
import '../models/activity_path.dart';

class ActivityPathsRepository {
  ActivityPathsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<ActivityPath>> fetchActivityPaths() async {
    final pathsResponse = await _client
        .from(DatabaseTables.activityPaths)
        .select(
          'id, title, description, cover_image_url, is_archived, is_deleted, created_at',
        )
        .order('created_at', ascending: false);
    final pathRows = pathsResponse.cast<Map<String, dynamic>>();

    final pagesByPathId = await _pagesByPathId();
    final selectedCounts = await _selectedCountsByPathId();

    return [
      for (final row in pathRows)
        ActivityPath.fromJson(
          row,
          selectedUserCount: selectedCounts[row['id'] as String] ?? 0,
          pages: pagesByPathId[row['id'] as String] ?? const [],
        ),
    ];
  }

  Future<void> createActivityPath(ActivityPathDraft input) async {
    final path = await _client
        .from(DatabaseTables.activityPaths)
        .insert({
          'title': input.title,
          'description': input.description,
          'cover_image_url': await _coverImageUrl(null, input),
          'created_by': input.createdBy,
        })
        .select('id')
        .single();

    await _insertPages(
      activityPathId: path['id'] as String,
      pages: input.pages,
    );
  }

  Future<void> updateActivityPath({
    required String activityPathId,
    required ActivityPathDraft input,
  }) async {
    await _client.from(DatabaseTables.activityPaths).update({
      'title': input.title,
      'description': input.description,
      'cover_image_url': await _coverImageUrl(activityPathId, input),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', activityPathId);

    await _client
        .from(DatabaseTables.activityPathPages)
        .delete()
        .eq('activity_path_id', activityPathId);

    await _insertPages(activityPathId: activityPathId, pages: input.pages);
  }

  Future<void> archiveActivityPath(String activityPathId) {
    return _client
        .from(DatabaseTables.activityPaths)
        .update({'is_archived': true})
        .eq('id', activityPathId);
  }

  Future<void> unarchiveActivityPath(String activityPathId) {
    return _client
        .from(DatabaseTables.activityPaths)
        .update({'is_archived': false})
        .eq('id', activityPathId);
  }

  Future<void> deleteActivityPath(String activityPathId) {
    return _client
        .from(DatabaseTables.activityPaths)
        .update({'is_deleted': true, 'is_archived': false})
        .eq('id', activityPathId);
  }

  Future<Map<String, List<ActivityPathPage>>> _pagesByPathId() async {
    final rows = await _client
        .from(DatabaseTables.activityPathPages)
        .select(
          'id, activity_path_id, page_number, title, body, '
          'activity_path_page_images(id, page_id, image_url, sort_order)',
        )
        .order('page_number', ascending: true);

    final pagesByPathId = <String, List<ActivityPathPage>>{};
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final page = ActivityPathPage.fromJson(row);
      pagesByPathId.putIfAbsent(page.activityPathId, () => []).add(page);
    }
    return pagesByPathId;
  }

  Future<Map<String, int>> _selectedCountsByPathId() async {
    final rows = await _client
        .from(DatabaseTables.userActivityPaths)
        .select('activity_path_id');

    final counts = <String, int>{};
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final pathId = row['activity_path_id'] as String;
      counts[pathId] = (counts[pathId] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _insertPages({
    required String activityPathId,
    required List<ActivityPathPageDraft> pages,
  }) async {
    for (var index = 0; index < pages.length; index += 1) {
      final page = pages[index];
      final pageRow = await _client
          .from(DatabaseTables.activityPathPages)
          .insert({
            'activity_path_id': activityPathId,
            'page_number': index + 1,
            'title': page.title,
            'body': page.body,
          })
          .select('id')
          .single();

      final pageId = pageRow['id'] as String;
      final imageRows = <Map<String, dynamic>>[];
      for (var imageIndex = 0; imageIndex < page.images.length; imageIndex += 1) {
        final imageUrl = await _imageUrl(
          activityPathId: activityPathId,
          pageId: pageId,
          image: page.images[imageIndex],
        );
        if (imageUrl == null || imageUrl.isEmpty) {
          continue;
        }
        imageRows.add({
          'page_id': pageId,
          'image_url': imageUrl,
          'sort_order': imageIndex,
        });
      }

      if (imageRows.isNotEmpty) {
        await _client
            .from(DatabaseTables.activityPathPageImages)
            .insert(imageRows);
      }
    }
  }

  Future<String?> _imageUrl({
    required String activityPathId,
    required String pageId,
    required ActivityPathImageDraft image,
  }) async {
    final bytes = image.imageBytes;
    if (bytes == null || bytes.isEmpty) {
      return image.imageUrl;
    }

    final fileName = _safeFileName(image.imageFileName ?? 'activity-path-image');
    final path =
        '$activityPathId/$pageId/${DateTime.now().microsecondsSinceEpoch}_$fileName';

    await _client.storage
        .from(DatabaseTables.activityPathImagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: image.imageMimeType ?? 'application/octet-stream',
            upsert: true,
          ),
        );

    return _client.storage
        .from(DatabaseTables.activityPathImagesBucket)
        .getPublicUrl(path);
  }

  Future<String?> _coverImageUrl(
    String? activityPathId,
    ActivityPathDraft input,
  ) async {
    final bytes = input.coverImageBytes;
    if (bytes == null || bytes.isEmpty) {
      return input.coverImageUrl;
    }

    final fileName =
        _safeFileName(input.coverImageFileName ?? 'activity-path-cover');
    final folder = activityPathId ?? 'new';
    final path = '$folder/cover/${DateTime.now().microsecondsSinceEpoch}_$fileName';

    await _client.storage
        .from(DatabaseTables.activityPathImagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: input.coverImageMimeType ?? 'application/octet-stream',
            upsert: true,
          ),
        );

    return _client.storage
        .from(DatabaseTables.activityPathImagesBucket)
        .getPublicUrl(path);
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}
