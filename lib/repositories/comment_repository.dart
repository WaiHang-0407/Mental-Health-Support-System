// repositories/comment_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment.dart';

class CommentRepository {
  final supabase = Supabase.instance.client;
  String get _uid => supabase.auth.currentUser!.id;

  // repositories/comment_repository.dart
  Future<List<Comment>> getComments(String postId) async {
    // Step 1: fetch comments
    final data = await supabase
        .from('comments')
        .select('''
        id, post_id, patient_id, parent_id, content, is_deleted, created_at,
        comment_likes(count)
      ''')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    if ((data as List).isEmpty) return [];

    // Step 2: get names separately
    final patientIds = data.map((c) => c['patient_id']).toList();

    final patientData = await supabase
        .from('patients')
        .select('id, name')
        .inFilter('id', patientIds);

    final nameMap = {for (final p in patientData as List) p['id']: p['name']};

    // Step 3: get liked comment ids
    final commentIds = data.map((c) => c['id']).toList();

    final likes = await supabase
        .from('comment_likes')
        .select('comment_id')
        .eq('patient_id', _uid)
        .inFilter('comment_id', commentIds);

    final likedIds = (likes as List).map((l) => l['comment_id']).toSet();

    final allComments = data.map((c) {
      final map = {
        ...c,
        'author_name': nameMap[c['patient_id']] ?? 'Anonymous',
        'like_count': (c['comment_likes'] as List?)?.first?['count'] ?? 0,
      };
      return Comment.fromMap(map, isLiked: likedIds.contains(c['id']));
    }).toList();

    // Step 4: nest replies
    final topLevel = allComments.where((c) => c.parentId == null).toList();
    return topLevel.map((c) {
      final replies = allComments.where((r) => r.parentId == c.id).toList();
      return Comment(
        id: c.id,
        postId: c.postId,
        patientId: c.patientId,
        content: c.content,
        isDeleted: c.isDeleted,
        likeCount: c.likeCount,
        isLiked: c.isLiked,
        authorName: c.authorName,
        replies: replies,
        createdAt: c.createdAt,
      );
    }).toList();
  }

  Future<void> addComment(
    String postId,
    String content, {
    String? parentId,
  }) async {
    await supabase.from('comments').insert({
      'post_id': postId,
      'patient_id': _uid,
      'content': content,
      if (parentId != null) 'parent_id': parentId,
    });
    await _log('comment_created', targetId: postId);
  }

  Future<void> softDeleteComment(String commentId) async {
    await supabase
        .from('comments')
        .update({'is_deleted': true, 'deleted_by': _uid})
        .eq('id', commentId);
  }

  Future<void> toggleLike(String commentId, bool isLiked) async {
    if (isLiked) {
      await supabase
          .from('comment_likes')
          .delete()
          .eq('comment_id', commentId)
          .eq('patient_id', _uid);
    } else {
      await supabase.from('comment_likes').insert({
        'comment_id': commentId,
        'patient_id': _uid,
      });
    }
  }

  Future<void> reportComment(String commentId, String reason) async {
    await supabase.from('reports').insert({
      'reporter_id': _uid,
      'comment_id': commentId,
      'reason': reason,
    });
  }

  Future<void> _log(String action, {String? targetId}) async {
    await supabase.from('user_activity_logs').insert({
      'patient_id': _uid,
      'action': action,
      'target_type': 'comment',
      if (targetId != null) 'target_id': targetId,
    });
  }
}
