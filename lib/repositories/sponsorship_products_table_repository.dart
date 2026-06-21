import 'package:supabase_flutter/supabase_flutter.dart';

class SponsorshipProductsTableRepository {
  final SupabaseClient supabase;

  SponsorshipProductsTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> getVisibleBySponsorship(String sponsorshipId) async {
    return await supabase
        .from('sponsorship_products')
        .select()
        .eq('sponsorship_id', sponsorshipId)
        .eq('is_deleted', false)
        .eq('is_archived', false)
        .order('created_at', ascending: false);
  }
}
