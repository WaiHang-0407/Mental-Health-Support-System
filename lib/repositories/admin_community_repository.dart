import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/database_tables.dart';
import '../models/admin_community_post.dart';

class AdminCommunityRepository {
  AdminCommunityRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<AdminCommunityPost>> fetchPosts() async {
    final rows = await _client
        .from(DatabaseTables.posts)
        .select(
          'id, patient_id, content, image_urls, is_deleted, is_archived, '
          'created_at, post_likes(count), comments(count)',
        )
        .order('created_at', ascending: false);

    final castRows = rows.cast<Map<String, dynamic>>();
    final patientIds = {
      for (final row in castRows) row['patient_id']?.toString(),
    }..remove(null);

    final patientRows = patientIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : (await _client
                  .from(DatabaseTables.patients)
                  .select('id, name, avatar_url')
                  .inFilter('id', patientIds.toList()))
              .cast<Map<String, dynamic>>();

    final namesById = {
      for (final row in patientRows)
        row['id']?.toString(): row['name']?.toString(),
    };
    final avatarsById = {
      for (final row in patientRows)
        row['id']?.toString(): row['avatar_url']?.toString(),
    };

    return [
      for (final row in castRows)
        AdminCommunityPost.fromJson(
          row,
          authorName: namesById[row['patient_id']?.toString()],
          authorAvatarUrl: avatarsById[row['patient_id']?.toString()],
        ),
    ];
  }

  Future<AdminCommunityPostDetails> fetchPostDetails(
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
      if (post.patientId.isNotEmpty) post.patientId,
    };
    final profilesById = await _fetchPatientProfiles(patientIds);

    return AdminCommunityPostDetails(
      post: post,
      likes: [
        for (final row in likesRows)
          AdminCommunityLike.fromJson(
            row,
            authorName: profilesById[row['patient_id']?.toString()]?['name'],
            authorAvatarUrl:
                profilesById[row['patient_id']?.toString()]?['avatar_url'],
          ),
      ],
      comments: [
        for (final row in commentRows)
          AdminCommunityComment.fromJson(
            row,
            authorName: profilesById[row['patient_id']?.toString()]?['name'],
            authorAvatarUrl:
                profilesById[row['patient_id']?.toString()]?['avatar_url'],
          ),
      ],
    );
  }

  Future<List<AdminCommunityReport>> fetchReports() async {
    final reportRows =
        (await _client
                .from(DatabaseTables.reports)
                .select(
                  'id, reporter_id, post_id, comment_id, reason, status, '
                  'reviewed_by, resolution_action, resolution_note, '
                  'resolved_at, created_at',
                )
                .order('created_at', ascending: false))
            .cast<Map<String, dynamic>>();

    if (reportRows.isEmpty) return const [];

    final postIds = <String>{
      for (final row in reportRows)
        if (row['post_id'] != null) row['post_id'].toString(),
    };
    final commentIds = <String>{
      for (final row in reportRows)
        if (row['comment_id'] != null) row['comment_id'].toString(),
    };

    final postRows = postIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : (await _client
                  .from(DatabaseTables.posts)
                  .select(
                    'id, patient_id, content, image_urls, is_deleted, is_archived, '
                    'created_at, post_likes(count), comments(count)',
                  )
                  .inFilter('id', postIds.toList()))
              .cast<Map<String, dynamic>>();

    final commentRows = commentIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : (await _client
                  .from(DatabaseTables.comments)
                  .select(
                    'id, post_id, patient_id, parent_id, content, is_deleted, is_archived, created_at',
                  )
                  .inFilter('id', commentIds.toList()))
              .cast<Map<String, dynamic>>();

    final patientIds = <String>{
      for (final row in reportRows)
        if (row['reporter_id'] != null) row['reporter_id'].toString(),
      for (final row in postRows)
        if (row['patient_id'] != null) row['patient_id'].toString(),
      for (final row in commentRows)
        if (row['patient_id'] != null) row['patient_id'].toString(),
    };
    final profilesById = await _fetchPatientProfiles(patientIds);

    final postsById = {
      for (final row in postRows)
        if (row['id'] != null)
          row['id'].toString(): AdminCommunityPost.fromJson(
            row,
            authorName: profilesById[row['patient_id']?.toString()]?['name'],
            authorAvatarUrl:
                profilesById[row['patient_id']?.toString()]?['avatar_url'],
          ),
    };
    final commentsById = {
      for (final row in commentRows)
        if (row['id'] != null)
          row['id'].toString(): AdminCommunityComment.fromJson(
            row,
            authorName: profilesById[row['patient_id']?.toString()]?['name'],
            authorAvatarUrl:
                profilesById[row['patient_id']?.toString()]?['avatar_url'],
          ),
    };

    return [
      for (final row in reportRows)
        _reportFromRow(
          row,
          profilesById: profilesById,
          postsById: postsById,
          commentsById: commentsById,
        ),
    ];
  }

  Future<void> archivePost(String postId) {
    final adminId = _client.auth.currentUser?.id;
    return _client
        .from(DatabaseTables.posts)
        .update({
          'is_archived': true,
          'archived_by': adminId,
          'archived_reason': 'Archived by admin moderation',
          'archived_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', postId);
  }

  Future<void> unarchivePost(String postId) {
    return _client
        .from(DatabaseTables.posts)
        .update({
          'is_archived': false,
          'archived_by': null,
          'archived_reason': null,
          'archived_at': null,
        })
        .eq('id', postId);
  }

  Future<void> archiveComment(String commentId) {
    final adminId = _client.auth.currentUser?.id;
    return _client
        .from(DatabaseTables.comments)
        .update({
          'is_archived': true,
          'archived_by': adminId,
          'archived_reason': 'Archived by admin moderation',
          'archived_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', commentId);
  }

  Future<void> unarchiveComment(String commentId) {
    return _client
        .from(DatabaseTables.comments)
        .update({
          'is_archived': false,
          'archived_by': null,
          'archived_reason': null,
          'archived_at': null,
        })
        .eq('id', commentId);
  }

  Future<void> sendWarning(AdminUserWarning warning) async {
    final adminId = _client.auth.currentUser?.id;
    if (adminId == null) return;

    await _client
        .from(DatabaseTables.userWarnings)
        .insert(warning.toCreateJson(adminId));
  }

  Future<void> resolveReport({
    required String reportId,
    required String status,
    required String resolutionAction,
    String? resolutionNote,
  }) async {
    final adminId = _client.auth.currentUser?.id;
    if (adminId == null) return;

    await _client
        .from(DatabaseTables.reports)
        .update({
          'status': status,
          'reviewed_by': adminId,
          'resolution_action': resolutionAction,
          'resolution_note': resolutionNote?.trim().isEmpty == true
              ? null
              : resolutionNote?.trim(),
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', reportId);
  }

  AdminCommunityReport _reportFromRow(
    Map<String, dynamic> row, {
    required Map<String, Map<String, String?>> profilesById,
    required Map<String, AdminCommunityPost> postsById,
    required Map<String, AdminCommunityComment> commentsById,
  }) {
    final reporterId = row['reporter_id']?.toString();
    final post = postsById[row['post_id']?.toString()];
    final comment = commentsById[row['comment_id']?.toString()];
    final reportedPatientId = post?.patientId ?? comment?.patientId;

    return AdminCommunityReport.fromJson(
      row,
      reporterName: profilesById[reporterId]?['name'],
      reporterAvatarUrl: profilesById[reporterId]?['avatar_url'],
      reportedAuthorName: profilesById[reportedPatientId]?['name'],
      reportedAuthorAvatarUrl: profilesById[reportedPatientId]?['avatar_url'],
      reportedContent: post?.content ?? comment?.content,
      post: post,
      comment: comment,
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
}
