// models/community_activity.dart
class CommunityActivity {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final DateTime? eventDate;
  final String? location;
  final DateTime? registrationDeadline;
  final int? maxParticipants;
  final int registeredCount;
  final bool isDeleted;
  final bool isArchived;
  final bool isRegistered;
  final String? createdBy;
  final DateTime createdAt;

  CommunityActivity({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.eventDate,
    this.location,
    this.registrationDeadline,
    this.maxParticipants,
    this.registeredCount = 0,
    this.isDeleted = false,
    this.isArchived = false,
    this.isRegistered = false,
    this.createdBy,
    required this.createdAt,
  });

  factory CommunityActivity.fromMap(
    Map<String, dynamic> map, {
    bool isRegistered = false,
  }) {
    String? cleanText(dynamic value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
        return null;
      }
      return text;
    }

    DateTime? cleanDate(dynamic value) {
      final text = cleanText(value);
      return text == null ? null : DateTime.parse(text);
    }

    return CommunityActivity(
      id: map['id'],
      title: cleanText(map['title']) ?? 'Untitled activity',
      description: cleanText(map['description']),
      imageUrl: cleanText(map['image_url']),
      eventDate: cleanDate(map['event_date']),
      location: cleanText(map['location']),
      registrationDeadline: cleanDate(map['registration_deadline']),
      maxParticipants: map['max_participants'],
      registeredCount: map['registered_count'] ?? 0,
      isDeleted: map['is_deleted'] ?? false,
      isArchived: map['is_archived'] ?? false,
      isRegistered: isRegistered,
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (eventDate != null) 'event_date': eventDate!.toIso8601String(),
      if (location != null) 'location': location,
      if (registrationDeadline != null)
        'registration_deadline': registrationDeadline!.toIso8601String(),
      if (maxParticipants != null) 'max_participants': maxParticipants,
      'is_deleted': isDeleted,
      'is_archived': isArchived,
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
