import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';

class ReportsTableRepository {
  final SupabaseClient supabase;

  ReportsTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<void> insertPostReport({
    required String reporterId,
    required String postId,
    required String reason,
  }) async {
    final report = Report(
      reporterId: reporterId,
      postId: postId,
      reason: reason,
    );
    await supabase.from('reports').insert(report.toMap());
  }

  Future<void> insertCommentReport({
    required String reporterId,
    required String commentId,
    required String reason,
  }) async {
    final report = Report(
      reporterId: reporterId,
      commentId: commentId,
      reason: reason,
    );
    await supabase.from('reports').insert(report.toMap());
  }
}
