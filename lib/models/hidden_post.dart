class HiddenPost {
  final String? id;
  final String postId;
  final String patientId;
  final DateTime? createdAt;

  HiddenPost({
    this.id,
    required this.postId,
    required this.patientId,
    this.createdAt,
  });

  factory HiddenPost.fromMap(Map<String, dynamic> map) {
    return HiddenPost(
      id: map['id'],
      postId: map['post_id'],
      patientId: map['patient_id'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'post_id': postId,
      'patient_id': patientId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
