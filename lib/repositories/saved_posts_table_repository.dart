import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/saved_post.dart';

class SavedPostsTableRepository {
  final SupabaseClient supabase;

  SavedPostsTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> findSavedPostIds(
    String patientId, {
    List? postIds,
  }) async {
    var query = supabase
        .from('saved_posts')
        .select('post_id')
        .eq('patient_id', patientId);
    if (postIds != null) query = query.inFilter('post_id', postIds);
    return await query;
  }

  Future<void> insert(String postId, String patientId) async {
    final savedPost = SavedPost(postId: postId, patientId: patientId);
    await supabase.from('saved_posts').insert(savedPost.toMap());
  }

  Future<void> delete(String postId, String patientId) async {
    await supabase
        .from('saved_posts')
        .delete()
        .eq('post_id', postId)
        .eq('patient_id', patientId);
  }
}
