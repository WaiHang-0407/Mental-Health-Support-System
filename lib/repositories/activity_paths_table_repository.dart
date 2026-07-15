import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityPathsTableRepository {
  final SupabaseClient supabase;

  ActivityPathsTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> getActivePaths() async {
    return await supabase
        .from('activity_paths')
        .select()
        .eq('is_deleted', false)
        .eq('is_archived', false)
        .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>?> getActivePathById(String activityPathId) async {
    final data = await supabase
        .from('activity_paths')
        .select()
        .eq('id', activityPathId)
        .eq('is_deleted', false)
        .eq('is_archived', false)
        .maybeSingle();

    return data == null ? null : Map<String, dynamic>.from(data);
  }
}
