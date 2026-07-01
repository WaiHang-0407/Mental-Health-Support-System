// controllers/journal_controller.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal.dart';
import '../repositories/journal_table_repository.dart';
import '../services/emotion_analysis.dart';
import '../services/journal_encryption_service.dart';

class JournalController {
  final JournalTableRepository _journalRepo = JournalTableRepository();
  final EmotionAnalysisService _emotionService = EmotionAnalysisService();
  final JournalEncryptionService _encryptionService =
      JournalEncryptionService();
  final supabase = Supabase.instance.client;

  String? get currentUserId => supabase.auth.currentUser?.id;

  Future<List<JournalModel>> getJournals() async {
    final userId = currentUserId;

    if (userId == null) {
      debugPrint('Get journals failed: user is not logged in');
      return [];
    }

    return await _journalRepo.getJournals(userId);
  }

  Future<String?> createJournal({
    String? title,
    required String content,
  }) async {
    final userId = currentUserId;

    if (userId == null) {
      return 'User is not logged in.';
    }

    if (content.trim().isEmpty) {
      return 'Journal content cannot be empty.';
    }

    try {
      final analysis = await _emotionService.analyzeEmotion(content);
      final emotion = analysis['emotion'] as String?;

      await _journalRepo.createJournal(
        patientId: userId,
        titleEncrypted: title == null || title.trim().isEmpty
            ? null
            : _encryptionService.encryptText(title.trim()),
        contentEncrypted: _encryptionService.encryptText(content.trim()),
        emotion: emotion ?? 'Unknown',
      );

      return null;
    } catch (e) {
      debugPrint('Create journal error: $e');
      return 'Failed to create journal.';
    }
  }

  Future<String?> updateJournal({
    required String journalId,
    String? title,
    required String content,
  }) async {
    final userId = currentUserId;

    if (userId == null) {
      return 'User is not logged in.';
    }

    if (content.trim().isEmpty) {
      return 'Journal content cannot be empty.';
    }

    try {
      final analysis = await _emotionService.analyzeEmotion(content);
      final emotion = analysis['emotion'] as String?;

      await _journalRepo.updateJournal(
        journalId: journalId,
        titleEncrypted: title == null || title.trim().isEmpty
            ? null
            : _encryptionService.encryptText(title.trim()),
        contentEncrypted: _encryptionService.encryptText(content.trim()),
        emotion: emotion ?? 'Unknown',
      );

      return null;
    } catch (e) {
      debugPrint('Update journal error: $e');
      return 'Failed to update journal.';
    }
  }

  Future<String?> deleteJournal(String journalId) async {
    final userId = currentUserId;

    if (userId == null) {
      return 'User is not logged in.';
    }

    try {
      await _journalRepo.deleteJournal(journalId);
      return null;
    } catch (e) {
      debugPrint('Delete journal error: $e');
      return 'Failed to delete journal.';
    }
  }

  Future<String?> deleteMultipleJournals(List<String> journalIds) async {
    if (journalIds.isEmpty) return 'No journals selected.';

    final userId = currentUserId;
    if (userId == null) return 'User is not logged in.';

    try {
      await _journalRepo.deleteJournals(journalIds);
      return null;
    } catch (e) {
      return 'Failed to delete selected journals.';
    }
  }

  Future<JournalModel?> getJournalById(String journalId) async {
    return await _journalRepo.getJournalById(journalId);
  }
}
