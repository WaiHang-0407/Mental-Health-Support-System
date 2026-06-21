// repositories/comment_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/comment.dart';
import 'comment_likes_table_repository.dart';
import 'hidden_comments_table_repository.dart';
import 'patient_table_repository.dart';
import 'reports_table_repository.dart';
import 'user_activity_logs_table_repository.dart';

class CommentRepository {
  final supabase = Supabase.instance.client;
  final _hiddenCommentsTable = HiddenCommentsTableRepository();
  final _patientRepo = PatientRepository();
  final _commentLikesTable = CommentLikesTableRepository();
  final _reportsTable = ReportsTableRepository();
  final _activityLogsTable = UserActivityLogsTableRepository();

  String get _uid => supabase.auth.currentUser!.id;

  Future<List<Comment>> getComments(String postId) async {
    final data = await supabase
        .from('comments')
        .select(
          'id, post_id, patient_id, parent_id, content, is_deleted, created_at, comment_likes(count)',
        )
        .eq('post_id', postId)
        .eq('is_deleted', false)
        .order('created_at', ascending: true);

    if ((data as List).isEmpty) return [];

    final hidden = await _hiddenCommentsTable.findHiddenCommentIds(_uid);
    final hiddenIds = hidden.map((h) => h['comment_id']).toSet();
    data.removeWhere((c) => hiddenIds.contains(c['id']));
    if (data.isEmpty) return [];

    final patientIds = data.map((c) => c['patient_id']).toList();
    final patientData = await _patientRepo.findNamesByIds(patientIds);
    final nameMap = {for (final p in patientData) p['id']: p['name']};

    final commentIds = data.map((c) => c['id']).toList();
    final likes = await _commentLikesTable.findLikedCommentIds(
      _uid,
      commentIds,
    );
    final likedIds = likes.map((l) => l['comment_id']).toSet();

    final allComments = data.map((c) {
      final map = <String, dynamic>{
        ...Map<String, dynamic>.from(c),
        'author_name': nameMap[c['patient_id']] ?? 'Anonymous',
        'like_count': (c['comment_likes'] as List?)?.first?['count'] ?? 0,
      };
      return Comment.fromMap(map, isLiked: likedIds.contains(c['id']));
    }).toList();

    final childrenByParent = <String, List<Comment>>{};
    final loadedCommentIds = allComments.map((c) => c.id).toSet();

    for (final comment in allComments) {
      final parentId = comment.parentId;
      if (parentId == null || !loadedCommentIds.contains(parentId)) continue;
      childrenByParent.putIfAbsent(parentId, () => []).add(comment);
    }

    List<Comment> flattenReplies(String parentId) {
      final directReplies = childrenByParent[parentId] ?? [];
      return directReplies.expand((reply) {
        return [reply, ...flattenReplies(reply.id)];
      }).toList();
    }

    final topLevel = allComments.where((c) {
      return c.parentId == null || !loadedCommentIds.contains(c.parentId);
    }).toList();

    return topLevel.map((comment) {
      return Comment(
        id: comment.id,
        postId: comment.postId,
        patientId: comment.patientId,
        parentId: comment.parentId,
        content: comment.content,
        isDeleted: comment.isDeleted,
        deletedBy: comment.deletedBy,
        likeCount: comment.likeCount,
        isLiked: comment.isLiked,
        authorName: comment.authorName,
        replies: flattenReplies(comment.id),
        createdAt: comment.createdAt,
      );
    }).toList();
  }

  Future<String?> getPostIdForCommentActivity(String commentId) async {
    final data = await supabase
        .from('comments')
        .select('post_id')
        .eq('id', commentId)
        .maybeSingle();
    return data?['post_id'];
  }

  Future<void> addComment(
    String postId,
    String content, {
    String? parentId,
  }) async {
    final comment = Comment(
      id: '',
      postId: postId,
      patientId: _uid,
      parentId: parentId,
      content: content,
      createdAt: DateTime.now(),
    );
    await supabase.from('comments').insert(comment.toCreateMap());
    await _log(
      parentId == null ? 'comment_created' : 'comment_replied',
      targetId: parentId ?? postId,
    );
  }

  Future<void> softDeleteComment(String commentId) async {
    await supabase
        .from('comments')
        .update({'is_deleted': true, 'deleted_by': _uid})
        .eq('id', commentId);
    await _log('comment_deleted', targetId: commentId);
  }

  Future<void> toggleLike(String commentId, bool isLiked) async {
    if (isLiked) {
      await _commentLikesTable.delete(commentId, _uid);
    } else {
      await _commentLikesTable.insert(commentId, _uid);
    }
  }

  Future<void> reportComment({
    required String commentId,
    required String commentOwnerId,
    required String reason,
  }) async {
    if (commentOwnerId == _uid) {
      throw StateError('Users cannot report their own comments.');
    }

    await _reportsTable.insertCommentReport(
      reporterId: _uid,
      commentId: commentId,
      reason: reason,
    );
    await _log('comment_reported', targetId: commentId);
  }

  Future<void> hideComment(String commentId) async {
    await _hiddenCommentsTable.upsert(commentId, _uid);
  }

  Future<void> _log(String action, {String? targetId}) async {
    await _activityLogsTable.insert(
      patientId: _uid,
      action: action,
      targetType: 'comment',
      targetId: targetId,
    );
  }
}
