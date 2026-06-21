import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hidden_comment.dart';

class HiddenCommentsTableRepository {
  final SupabaseClient supabase;

  HiddenCommentsTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> findHiddenCommentIds(String patientId) async {
    return await supabase
        .from('hidden_comments')
        .select('comment_id')
        .eq('patient_id', patientId);
  }

  Future<void> upsert(String commentId, String patientId) async {
    final hiddenComment = HiddenComment(
      commentId: commentId,
      patientId: patientId,
    );
    await supabase.from('hidden_comments').upsert(hiddenComment.toMap());
  }
}
