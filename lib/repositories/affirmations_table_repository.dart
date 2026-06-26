import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/affirmation.dart';

class AffirmationsTableRepository {
  final SupabaseClient supabase;

  AffirmationsTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<Affirmation>> fetchActiveAffirmations() async {
    final rows = await supabase
        .from('affirmations')
        .select('id, text')
        .eq('is_active', true)
        .order('created_at');

    return rows
        .map<Affirmation>((row) => Affirmation.fromMap(row))
        .toList(growable: false);
  }
}
