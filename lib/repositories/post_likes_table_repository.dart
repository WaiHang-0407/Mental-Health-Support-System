import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_like.dart';

class PostLikesTableRepository {
  final SupabaseClient supabase;

  PostLikesTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> findLikedPostIds(String patientId, List postIds) async {
    if (postIds.isEmpty) return [];
    return await supabase
        .from('post_likes')
        .select('post_id')
        .eq('patient_id', patientId)
        .inFilter('post_id', postIds);
  }

  Future<void> insert(String postId, String patientId) async {
    final postLike = PostLike(postId: postId, patientId: patientId);
    await supabase.from('post_likes').insert(postLike.toMap());
  }

  Future<void> delete(String postId, String patientId) async {
    await supabase
        .from('post_likes')
        .delete()
        .eq('post_id', postId)
        .eq('patient_id', patientId);
  }
}
