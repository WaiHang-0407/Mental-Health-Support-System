import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/database_tables.dart';
import '../models/affirmation.dart';

class AffirmationsRepository {
  AffirmationsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Affirmation>> fetchAffirmations() async {
    final rows = await _client
        .from(DatabaseTables.affirmations)
        .select('id, text, created_by, is_active, created_at')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        Affirmation.fromJson(row),
    ];
  }

  Future<void> createAffirmation({
    required String text,
    required String createdBy,
  }) {
    return _client.from(DatabaseTables.affirmations).insert({
      'text': text,
      'created_by': createdBy,
    });
  }

  Future<void> updateAffirmation({
    required String affirmationId,
    required String text,
  }) {
    return _client
        .from(DatabaseTables.affirmations)
        .update({'text': text})
        .eq('id', affirmationId);
  }

  Future<void> removeAffirmation(String affirmationId) {
    return _client
        .from(DatabaseTables.affirmations)
        .update({'is_active': false})
        .eq('id', affirmationId);
  }
}
