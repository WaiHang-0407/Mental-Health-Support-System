import 'package:supabase_flutter/supabase_flutter.dart';

class ActivitiesTableRepository {
  final SupabaseClient supabase;

  ActivitiesTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> getVisibleActivities() async {
    return await supabase
        .from('activities')
        .select('*')
        .or('is_deleted.is.null,is_deleted.eq.false')
        .or('is_archived.is.null,is_archived.eq.false')
        .order('event_date', ascending: true);
  }

  Future<Map<String, dynamic>?> getVisibleActivityById(String activityId) async {
    final data = await supabase
        .from('activities')
        .select('*')
        .eq('id', activityId)
        .or('is_deleted.is.null,is_deleted.eq.false')
        .or('is_archived.is.null,is_archived.eq.false')
        .maybeSingle();

    return data == null ? null : Map<String, dynamic>.from(data);
  }
}
