// models/journal.dart
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
    return JournalModel(
      id: map['id'],
      patientID: map['patient_id'],
      title: map['title'],
      content: map['content'],
      emotion: map['emotion'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientID,
      'title': title,
      'content': content,
      'emotion': emotion,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
