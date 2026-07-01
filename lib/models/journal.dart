// models/journal.dart

import '../services/journal_encryption_service.dart';

class JournalModel {
  final String id;
  final String patientID;
  final String? title;
  final String content;
  final String? emotion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JournalModel({
    required this.id,
    required this.patientID,
    this.title,
    required this.content,
    required this.emotion,
    this.createdAt,
    this.updatedAt,
  });

  factory JournalModel.fromMap(Map<String, dynamic> map) {
    final encryptionService = JournalEncryptionService();

    String? decryptedTitle;
    String decryptedContent = '';

    try {
      final encryptedTitle = map['title_encrypted'];
      final encryptedContent = map['content_encrypted'];

      if (encryptedTitle != null &&
          encryptedTitle.toString().trim().isNotEmpty) {
        decryptedTitle = encryptionService.decryptText(
          encryptedTitle.toString(),
        );
      }

      if (encryptedContent != null &&
          encryptedContent.toString().trim().isNotEmpty) {
        decryptedContent = encryptionService.decryptText(
          encryptedContent.toString(),
        );
      }
    } catch (e) {
      decryptedTitle = 'Unable to decrypt title';
      decryptedContent = 'Unable to decrypt journal content';
    }

    return JournalModel(
      id: map['id'],
      patientID: map['patient_id'],
      title: decryptedTitle,
      content: decryptedContent,
      emotion: map['emotion'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientID,
      'title_encrypted': title,
      'content_encrypted': content,
      'emotion': emotion,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
