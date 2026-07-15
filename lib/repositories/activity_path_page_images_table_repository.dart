import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityPathPageImagesTableRepository {
  final SupabaseClient supabase;

  ActivityPathPageImagesTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> getImagesForPages(List<String> pageIds) async {
    if (pageIds.isEmpty) return const [];

    return await supabase
        .from('activity_path_page_images')
        .select()
        .inFilter('page_id', pageIds)
        .order('sort_order', ascending: true);
  }
}
