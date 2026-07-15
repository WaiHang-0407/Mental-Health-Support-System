class Sponsorship {
  final String? id;
  final String activityId;
  final String sponsorName;
  final String? description;
  final bool isDeleted;
  final bool isArchived;
  final DateTime? createdAt;

  Sponsorship({
    this.id,
    required this.activityId,
    required this.sponsorName,
    this.description,
    this.isDeleted = false,
    this.isArchived = false,
    this.createdAt,
  });

  factory Sponsorship.fromMap(Map<String, dynamic> map) {
    return Sponsorship(
      id: map['id'],
      activityId: map['activity_id'] ?? '',
      sponsorName: map['sponsor_name'],
      description: map['description'],
      isDeleted: map['is_deleted'] ?? false,
      isArchived: map['is_archived'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'activity_id': activityId,
      'sponsor_name': sponsorName,
      if (description != null) 'description': description,
      'is_deleted': isDeleted,
      'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
