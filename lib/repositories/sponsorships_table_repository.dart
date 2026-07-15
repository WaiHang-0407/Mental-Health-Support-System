import 'package:supabase_flutter/supabase_flutter.dart';

class SponsorshipsTableRepository {
  final SupabaseClient supabase;

  SponsorshipsTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> getVisibleByActivity(String activityId) async {
    final links = await supabase
        .from('activity_sponsorships')
        .select('sponsorship_id')
        .eq('activity_id', activityId);

    final sponsorIds = links
        .map((link) => link['sponsorship_id'] as String?)
        .whereType<String>()
        .toList();

    if (sponsorIds.isEmpty) return const [];

    return await supabase
        .from('sponsorships')
        .select()
        .inFilter('id', sponsorIds)
        .eq('is_deleted', false)
        .eq('is_archived', false)
        .order('created_at', ascending: false);
  }
}
