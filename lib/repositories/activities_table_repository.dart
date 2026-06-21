import 'package:supabase_flutter/supabase_flutter.dart';

class ActivitiesTableRepository {
  final SupabaseClient supabase;

  ActivitiesTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> getVisibleActivities() async {
    return await supabase
        .from('activities')
        .select('*, activity_registrations(count)')
        .eq('is_deleted', false)
        .eq('is_archived', false)
        .order('event_date', ascending: true);
  }
}
