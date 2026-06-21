class HiddenComment {
  final String? id;
  final String commentId;
  final String patientId;
  final DateTime? createdAt;

  HiddenComment({
    this.id,
    required this.commentId,
    required this.patientId,
    this.createdAt,
  });

  factory HiddenComment.fromMap(Map<String, dynamic> map) {
    return HiddenComment(
      id: map['id'],
      commentId: map['comment_id'],
      patientId: map['patient_id'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'comment_id': commentId,
      'patient_id': patientId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
