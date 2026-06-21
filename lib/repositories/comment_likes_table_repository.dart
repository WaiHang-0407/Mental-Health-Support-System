import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_like.dart';

class CommentLikesTableRepository {
  final SupabaseClient supabase;

  CommentLikesTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> findLikedCommentIds(
    String patientId,
    List commentIds,
  ) async {
    if (commentIds.isEmpty) return [];
    return await supabase
        .from('comment_likes')
        .select('comment_id')
        .eq('patient_id', patientId)
        .inFilter('comment_id', commentIds);
  }

  Future<void> insert(String commentId, String patientId) async {
    final commentLike = CommentLike(commentId: commentId, patientId: patientId);
    await supabase.from('comment_likes').insert(commentLike.toMap());
  }

  Future<void> delete(String commentId, String patientId) async {
    await supabase
        .from('comment_likes')
        .delete()
        .eq('comment_id', commentId)
        .eq('patient_id', patientId);
  }
}
