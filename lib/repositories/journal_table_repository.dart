// repositories/journal_table_repository.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal.dart';

class JournalTableRepository {
  final supabase = Supabase.instance.client;

  Future<List<JournalModel>> getJournalsForWeek(String patientId) async {
    try {
      final now = DateTime.now();

      final monday = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      final nextMonday = monday.add(const Duration(days: 7));

      final data = await supabase
          .from('journal')
          .select()
          .eq('patient_id', patientId)
          .gte('created_at', monday.toUtc().toIso8601String())
          .lt('created_at', nextMonday.toUtc().toIso8601String())
          .order('created_at', ascending: true);

      return (data as List)
          .map((e) => JournalModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Get weekly journals error: $e");
      return [];
    }
  }

  Future<List<JournalModel>> getJournals(String patientId) async {
    try {
      final data = await supabase
          .from('journal')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => JournalModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Get journals error: $e");
      return [];
    }
  }

  Future<void> createJournal({
    required String patientId,
    String? title,
    required String content,
    String? emotion,
  }) async {
    await supabase.from('journal').insert({
      'patient_id': patientId,
      'title': title,
      'content': content,
      'emotion': emotion,
    });
  }

  Future<void> updateJournal({
    required String journalId,
    String? title,
    required String content,
    String? emotion,
  }) async {
    await supabase
        .from('journal')
        .update({
          'title': title,
          'content': content,
          'emotion': emotion,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', journalId);
  }

  Future<void> deleteJournals(List<String> journalIds) async {
    await supabase.from('journal').delete().inFilter('id', journalIds);
  }

  Future<void> deleteJournal(String journalId) async {
    await supabase.from('journal').delete().eq('id', journalId);
  }

  Future<JournalModel?> getJournalById(String journalId) async {
    try {
      final data = await supabase
          .from('journal')
          .select()
          .eq('id', journalId)
          .maybeSingle();

      if (data == null) return null;
      return JournalModel.fromMap(data);
    } catch (e) {
      debugPrint("Get journal by id error: $e");
      return null;
    }
  }
}
