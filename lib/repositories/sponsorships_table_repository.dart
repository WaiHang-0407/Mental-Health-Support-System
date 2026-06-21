import 'package:supabase_flutter/supabase_flutter.dart';

class SponsorshipsTableRepository {
  final SupabaseClient supabase;

  SponsorshipsTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> getVisibleByActivity(String activityId) async {
    return await supabase
        .from('sponsorships')
        .select()
        .eq('activity_id', activityId)
        .eq('is_deleted', false)
        .eq('is_archived', false)
        .order('created_at', ascending: false);
  }
}
