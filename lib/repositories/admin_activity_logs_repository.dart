import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/database_tables.dart';
import '../models/admin_activity_log.dart';
import '../models/admin_community_post.dart';

class AdminActivityLogsRepository {
  AdminActivityLogsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<AdminActivityLog>> fetchLogs({int limit = 100}) async {
    final rows = await _client
        .from(DatabaseTables.adminActivityLogs)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        AdminActivityLog.fromJson(row),
    ];
  }

  Future<void> insert(AdminActivityLog log) {
    return _client
        .from(DatabaseTables.adminActivityLogs)
        .insert(log.toCreateJson());
  }

  Future<AdminActivityLogTargetDetails?> fetchTargetDetails(
    AdminActivityLog log,
  ) async {
    final targetType = log.targetType?.trim();
    final targetId = log.targetId?.trim();
    if (targetType == null ||
        targetType.isEmpty ||
        targetId == null ||
        targetId.isEmpty) {
      return null;
    }

    final normalizedType = targetType.toLowerCase();
    if (normalizedType == 'post') {
      return _fetchPostTarget(targetType: targetType, targetId: targetId);
    }
    if (normalizedType == 'comment') {
      return _fetchCommentTarget(targetType: targetType, targetId: targetId);
    }

    final tableName = _tableForTargetType(normalizedType);
    if (tableName == null) {
      return AdminActivityLogTargetDetails(
        title: 'Unsupported target type',
        targetType: targetType,
        targetId: targetId,
        fields: {
          'Target type': targetType,
          'Target ID': targetId,
          'Note': 'No detail resolver has been configured for this target.',
        },
      );
    }

    final row = await _client
        .from(tableName)
        .select()
        .eq('id', targetId)
        .maybeSingle();

    if (row == null) {
      return AdminActivityLogTargetDetails(
        title: 'Target not found',
        targetType: targetType,
        targetId: targetId,
        fields: {
          'Target type': targetType,
          'Target ID': targetId,
          'Table': tableName,
          'Status': 'No row found. It may have been deleted.',
        },
      );
    }

    final castRow = Map<String, dynamic>.from(row);
    return AdminActivityLogTargetDetails(
      title: _titleForGenericTarget(normalizedType, castRow),
      targetType: targetType,
      targetId: targetId,
      fields: _fieldsFromRow(castRow),
    );
  }

  Future<AdminActivityLogTargetDetails> _fetchPostTarget({
    required String targetType,
    required String targetId,
  }) async {
    final post = await _fetchPost(targetId);
    if (post == null) {
      return AdminActivityLogTargetDetails(
        title: 'Post not found',
        targetType: targetType,
        targetId: targetId,
        fields: {'Status': 'No post row found.'},
      );
    }

    final details = await _fetchPostDetails(post);
    return AdminActivityLogTargetDetails(
      title: 'Community post by ${post.displayAuthor}',
      targetType: targetType,
      targetId: targetId,
      postDetails: details,
      fields: {
        'Author': post.displayAuthor,
        'Status': post.status,
        'Likes': details.likes.length.toString(),
        'Comments': details.comments.length.toString(),
        'Images': post.imageUrls.length.toString(),
        'Created at': _formatDate(post.createdAt),
      },
    );
  }

  Future<AdminActivityLogTargetDetails> _fetchCommentTarget({
    required String targetType,
    required String targetId,
  }) async {
    final row = await _client
        .from(DatabaseTables.comments)
        .select(
          'id, post_id, patient_id, parent_id, content, is_deleted, is_archived, created_at',
        )
        .eq('id', targetId)
        .maybeSingle();

    if (row == null) {
      return AdminActivityLogTargetDetails(
        title: 'Comment not found',
        targetType: targetType,
        targetId: targetId,
        fields: {'Status': 'No comment row found.'},
      );
    }

    final castRow = Map<String, dynamic>.from(row);
    final patientId = castRow['patient_id']?.toString();
    final profiles = await _fetchPatientProfiles({
      if (patientId != null) patientId,
    });
    final comment = AdminCommunityComment.fromJson(
      castRow,
      authorName: profiles[patientId]?['name'],
      authorAvatarUrl: profiles[patientId]?['avatar_url'],
    );
    final relatedPost = comment.postId.isEmpty
        ? null
        : await _fetchPost(comment.postId);

    return AdminActivityLogTargetDetails(
      title: 'Comment by ${comment.displayAuthor}',
      targetType: targetType,
      targetId: targetId,
      comment: comment,
      relatedPost: relatedPost,
      fields: {
        'Author': comment.displayAuthor,
        'Post ID': comment.postId,
        'Parent comment ID': comment.parentId ?? '-',
        'Deleted': comment.isDeleted ? 'Yes' : 'No',
        'Archived': comment.isArchived ? 'Yes' : 'No',
        'Created at': _formatDate(comment.createdAt),
      },
    );
  }

  Future<AdminCommunityPost?> _fetchPost(String postId) async {
    final row = await _client
        .from(DatabaseTables.posts)
        .select(
          'id, patient_id, content, image_urls, is_deleted, is_archived, '
          'created_at, post_likes(count), comments(count)',
        )
        .eq('id', postId)
        .maybeSingle();

    if (row == null) return null;

    final castRow = Map<String, dynamic>.from(row);
    final patientId = castRow['patient_id']?.toString();
    final profiles = await _fetchPatientProfiles({
      if (patientId != null) patientId,
    });

    return AdminCommunityPost.fromJson(
      castRow,
      authorName: profiles[patientId]?['name'],
      authorAvatarUrl: profiles[patientId]?['avatar_url'],
    );
  }

  Future<AdminCommunityPostDetails> _fetchPostDetails(
    AdminCommunityPost post,
  ) async {
    final likesRows =
        (await _client
                .from(DatabaseTables.postLikes)
                .select('id, patient_id, created_at')
                .eq('post_id', post.id)
                .order('created_at', ascending: false))
            .cast<Map<String, dynamic>>();
    final commentRows =
        (await _client
                .from(DatabaseTables.comments)
                .select(
                  'id, post_id, patient_id, parent_id, content, is_deleted, is_archived, created_at',
                )
                .eq('post_id', post.id)
                .order('created_at'))
            .cast<Map<String, dynamic>>();

    final patientIds = <String>{
      for (final row in likesRows)
        if (row['patient_id'] != null) row['patient_id'].toString(),
      for (final row in commentRows)
        if (row['patient_id'] != null) row['patient_id'].toString(),
    };
    final profiles = await _fetchPatientProfiles(patientIds);

    return AdminCommunityPostDetails(
      post: post,
      likes: [
        for (final row in likesRows)
          AdminCommunityLike.fromJson(
            row,
            authorName: profiles[row['patient_id']?.toString()]?['name'],
            authorAvatarUrl:
                profiles[row['patient_id']?.toString()]?['avatar_url'],
          ),
      ],
      comments: [
        for (final row in commentRows)
          AdminCommunityComment.fromJson(
            row,
            authorName: profiles[row['patient_id']?.toString()]?['name'],
            authorAvatarUrl:
                profiles[row['patient_id']?.toString()]?['avatar_url'],
          ),
      ],
    );
  }

  Future<Map<String, Map<String, String?>>> _fetchPatientProfiles(
    Set<String> patientIds,
  ) async {
    if (patientIds.isEmpty) return {};

    final rows =
        (await _client
                .from(DatabaseTables.patients)
                .select('id, name, avatar_url')
                .inFilter('id', patientIds.toList()))
            .cast<Map<String, dynamic>>();

    return {
      for (final row in rows)
        if (row['id'] != null)
          row['id'].toString(): {
            'name': row['name']?.toString(),
            'avatar_url': row['avatar_url']?.toString(),
          },
    };
  }

  String? _tableForTargetType(String targetType) {
    return switch (targetType) {
      'user' => DatabaseTables.users,
      'daily_activity' => DatabaseTables.dailyActivities,
      'affirmation' => DatabaseTables.affirmations,
      'activity_path' => DatabaseTables.activityPaths,
      'community_activity' => DatabaseTables.activities,
      'sponsorship' => DatabaseTables.sponsorships,
      'sponsorship_product' => DatabaseTables.sponsorshipProducts,
      _ => null,
    };
  }

  String _titleForGenericTarget(String targetType, Map<String, dynamic> row) {
    final label = targetType.replaceAll('_', ' ');
    final name =
        row['title']?.toString() ??
        row['name']?.toString() ??
        row['sponsor_name']?.toString() ??
        row['text']?.toString() ??
        row['id']?.toString() ??
        'Target details';
    return '$label: $name';
  }

  Map<String, String> _fieldsFromRow(Map<String, dynamic> row) {
    final entries = row.entries.toList()
      ..sort((a, b) {
        const priority = [
          'id',
          'title',
          'name',
          'sponsor_name',
          'text',
          'description',
          'role',
          'is_active',
          'is_archived',
          'is_deleted',
          'created_at',
          'updated_at',
        ];
        final aIndex = priority.indexOf(a.key);
        final bIndex = priority.indexOf(b.key);
        if (aIndex == -1 && bIndex == -1) return a.key.compareTo(b.key);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });

    return {
      for (final entry in entries)
        _labelForField(entry.key): _stringValue(entry.value),
    };
  }

  String _labelForField(String key) {
    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _stringValue(dynamic value) {
    if (value == null) return '-';
    if (value is DateTime) return _formatDate(value);
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is List) return value.isEmpty ? '-' : value.join(', ');
    if (value is Map) return value.toString();

    final text = value.toString();
    final parsedDate = DateTime.tryParse(text);
    if (parsedDate != null && text.contains('-')) {
      return _formatDate(parsedDate);
    }
    return text;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }
}
