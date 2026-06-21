class ChatSession {
  final String id;
  final String patientId;
  final String title;
  final String? animal;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.patientId,
    required this.title,
    this.animal,
    required this.createdAt,
  });

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'],
      patientId: map['patient_id'],
      title: map['title'] ?? 'New Chat',
      animal: map['animal'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'title': title,
      if (animal != null) 'animal': animal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'patient_id': patientId,
      'title': title,
      if (animal != null) 'animal': animal,
    };
  }
}
