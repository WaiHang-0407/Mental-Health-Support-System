import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hidden_post.dart';

class HiddenPostsTableRepository {
  final SupabaseClient supabase;

  HiddenPostsTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> findHiddenPostIds(String patientId) async {
    return await supabase
        .from('hidden_posts')
        .select('post_id')
        .eq('patient_id', patientId);
  }

  Future<void> upsert(String postId, String patientId) async {
    final hiddenPost = HiddenPost(postId: postId, patientId: patientId);
    await supabase.from('hidden_posts').upsert(hiddenPost.toMap());
  }
}
