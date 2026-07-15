import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityPathPagesTableRepository {
  final SupabaseClient supabase;

  ActivityPathPagesTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> getPagesForPaths(List<String> activityPathIds) async {
    if (activityPathIds.isEmpty) return const [];

    return await supabase
        .from('activity_path_pages')
        .select()
        .inFilter('activity_path_id', activityPathIds)
        .order('page_number', ascending: true);
  }
}
