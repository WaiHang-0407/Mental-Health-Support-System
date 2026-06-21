class ActivityRegistration {
  final String? id;
  final String activityId;
  final String patientId;
  final bool isCancelled;
  final DateTime? createdAt;

  ActivityRegistration({
    this.id,
    required this.activityId,
    required this.patientId,
    this.isCancelled = false,
    this.createdAt,
  });

  factory ActivityRegistration.fromMap(Map<String, dynamic> map) {
    return ActivityRegistration(
      id: map['id'],
      activityId: map['activity_id'],
      patientId: map['patient_id'],
      isCancelled: map['is_cancelled'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'activity_id': activityId,
      'patient_id': patientId,
      'is_cancelled': isCancelled,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
