import 'dart:typed_data';

class CommunityActivity {
  const CommunityActivity({
    required this.id,
    required this.title,
    required this.createdAt,
    this.description,
    this.venue,
    this.eventDate,
    this.registrationDeadline,
    this.maxParticipants,
    this.isDeleted = false,
    this.isArchived = false,
    this.sponsorships = const [],
  });

  final String id;
  final String title;
  final DateTime? createdAt;
  final String? description;
  final String? venue;
  final DateTime? eventDate;
  final DateTime? registrationDeadline;
  final int? maxParticipants;
  final bool isDeleted;
  final bool isArchived;
  final List<ActivitySponsorship> sponsorships;

  String get status {
    if (isDeleted) {
      return 'Deleted';
    }
    if (isArchived) {
      return 'Archived';
    }
    return 'Active';
  }

  factory CommunityActivity.fromJson(Map<String, dynamic> json) {
    return CommunityActivity(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      venue: json['location'] as String?,
      eventDate: _parseDate(json['event_date']),
      registrationDeadline: _parseDate(json['registration_deadline']),
      maxParticipants: json['max_participants'] as int?,
      isDeleted: _parseBool(json['is_deleted']),
      isArchived: _parseBool(json['is_archived']),
      createdAt: _parseDate(json['created_at']),
      sponsorships: [
        for (final row in (json['sponsorships'] as List<dynamic>? ?? const []))
          ActivitySponsorship.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value as String);
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }
}

class ActivitySponsorship {
  const ActivitySponsorship({
    required this.id,
    required this.sponsorName,
    required this.createdAt,
    this.activityId,
    this.description,
    this.isDeleted = false,
    this.isArchived = false,
    this.products = const [],
  });

  final String id;
  final String? activityId;
  final String sponsorName;
  final String? description;
  final bool isDeleted;
  final bool isArchived;
  final DateTime? createdAt;
  final List<SponsorshipProduct> products;

  String get status {
    if (isDeleted) {
      return 'Deleted';
    }
    if (isArchived) {
      return 'Archived';
    }
    return 'Active';
  }

  factory ActivitySponsorship.fromJson(Map<String, dynamic> json) {
    return ActivitySponsorship(
      id: json['id'] as String,
      activityId: json['activity_id'] as String?,
      sponsorName: json['sponsor_name'] as String? ?? '',
      description: json['description'] as String?,
      isDeleted: CommunityActivity._parseBool(json['is_deleted']),
      isArchived: CommunityActivity._parseBool(json['is_archived']),
      createdAt: CommunityActivity._parseDate(json['created_at']),
      products: [
        for (final row
            in (json['sponsorship_products'] as List<dynamic>? ?? const []))
          SponsorshipProduct.fromJson(row as Map<String, dynamic>),
      ],
    );
  }
}

class SponsorshipProduct {
  const SponsorshipProduct({
    required this.id,
    required this.sponsorshipId,
    required this.name,
    required this.createdAt,
    this.description,
    this.imageUrl,
    this.isDeleted = false,
    this.isArchived = false,
  });

  final String id;
  final String sponsorshipId;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isDeleted;
  final bool isArchived;
  final DateTime? createdAt;

  String get status {
    if (isDeleted) {
      return 'Deleted';
    }
    if (isArchived) {
      return 'Archived';
    }
    return 'Active';
  }

  factory SponsorshipProduct.fromJson(Map<String, dynamic> json) {
    return SponsorshipProduct(
      id: json['id'] as String,
      sponsorshipId: json['sponsorship_id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isDeleted: CommunityActivity._parseBool(json['is_deleted']),
      isArchived: CommunityActivity._parseBool(json['is_archived']),
      createdAt: CommunityActivity._parseDate(json['created_at']),
    );
  }
}

class ActivityParticipant {
  const ActivityParticipant({
    required this.registrationId,
    required this.patientId,
    required this.createdAt,
    this.name,
    this.gender,
    this.phoneNo,
    this.isCancelled = false,
  });

  final String registrationId;
  final String patientId;
  final String? name;
  final String? gender;
  final String? phoneNo;
  final bool isCancelled;
  final DateTime? createdAt;

  factory ActivityParticipant.fromJson(Map<String, dynamic> json) {
    final patient = json['patients'] as Map<String, dynamic>?;

    return ActivityParticipant(
      registrationId: json['id'] as String,
      patientId: json['patient_id'] as String,
      isCancelled: json['is_cancelled'] as bool? ?? false,
      createdAt: CommunityActivity._parseDate(json['created_at']),
      name: patient?['name'] as String?,
      gender: patient?['gender'] as String?,
      phoneNo: patient?['phoneno'] as String?,
    );
  }
}

class SponsorshipProductDraft {
  const SponsorshipProductDraft({
    required this.name,
    this.description,
    this.imageUrl,
    this.imageBytes,
    this.imageFileName,
    this.imageMimeType,
  });

  final String name;
  final String? description;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? imageFileName;
  final String? imageMimeType;
}

class UpdateSponsorshipProductInput {
  const UpdateSponsorshipProductInput({
    required this.name,
    this.description,
    this.imageUrl,
    this.imageBytes,
    this.imageFileName,
    this.imageMimeType,
  });

  final String name;
  final String? description;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? imageFileName;
  final String? imageMimeType;
}

class SponsorshipDraft {
  const SponsorshipDraft({
    required this.sponsorName,
    this.description,
    this.products = const [],
  });

  final String sponsorName;
  final String? description;
  final List<SponsorshipProductDraft> products;
}

class CreateCommunityActivityInput {
  const CreateCommunityActivityInput({
    required this.title,
    required this.description,
    required this.venue,
    required this.eventDate,
    required this.registrationDeadline,
    required this.createdBy,
    this.maxParticipants,
    this.sponsorshipIds = const [],
  });

  final String title;
  final String description;
  final String venue;
  final DateTime eventDate;
  final DateTime registrationDeadline;
  final String createdBy;
  final int? maxParticipants;
  final List<String> sponsorshipIds;
}
