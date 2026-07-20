import 'dart:typed_data';

class ActivityPath {
  const ActivityPath({
    required this.id,
    required this.title,
    required this.createdAt,
    this.description,
    this.coverImageUrl,
    this.isArchived = false,
    this.isDeleted = false,
    this.selectedUserCount = 0,
    this.pages = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final bool isArchived;
  final bool isDeleted;
  final DateTime? createdAt;
  final int selectedUserCount;
  final List<ActivityPathPage> pages;

  String get status {
    if (isDeleted) {
      return 'Deleted';
    }
    if (isArchived) {
      return 'Archived';
    }
    return 'Active';
  }

  factory ActivityPath.fromJson(
    Map<String, dynamic> json, {
    int selectedUserCount = 0,
    List<ActivityPathPage> pages = const [],
  }) {
    return ActivityPath(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      isArchived: _parseBool(json['is_archived']),
      isDeleted: _parseBool(json['is_deleted']),
      createdAt: _parseDate(json['created_at']),
      selectedUserCount: selectedUserCount,
      pages: pages,
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

class ActivityPathPage {
  const ActivityPathPage({
    required this.id,
    required this.activityPathId,
    required this.pageNumber,
    required this.body,
    this.title,
    this.images = const [],
  });

  final String id;
  final String activityPathId;
  final int pageNumber;
  final String? title;
  final String body;
  final List<ActivityPathImage> images;

  factory ActivityPathPage.fromJson(Map<String, dynamic> json) {
    return ActivityPathPage(
      id: json['id'] as String,
      activityPathId: json['activity_path_id'] as String,
      pageNumber: json['page_number'] as int? ?? 0,
      title: json['title'] as String?,
      body: json['body'] as String? ?? '',
      images: [
        for (final row in (json['activity_path_page_images'] as List<dynamic>? ??
            const []))
          ActivityPathImage.fromJson(row as Map<String, dynamic>),
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }
}

class ActivityPathImage {
  const ActivityPathImage({
    required this.id,
    required this.pageId,
    required this.imageUrl,
    required this.sortOrder,
  });

  final String id;
  final String pageId;
  final String imageUrl;
  final int sortOrder;

  factory ActivityPathImage.fromJson(Map<String, dynamic> json) {
    return ActivityPathImage(
      id: json['id'] as String,
      pageId: json['page_id'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class ActivityPathImageDraft {
  const ActivityPathImageDraft({
    this.imageUrl,
    this.imageBytes,
    this.imageFileName,
    this.imageMimeType,
  });

  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? imageFileName;
  final String? imageMimeType;
}

class ActivityPathPageDraft {
  const ActivityPathPageDraft({
    required this.title,
    required this.body,
    this.images = const [],
  });

  final String title;
  final String body;
  final List<ActivityPathImageDraft> images;
}

class ActivityPathDraft {
  const ActivityPathDraft({
    required this.title,
    required this.description,
    required this.createdBy,
    required this.pages,
    this.coverImageUrl,
    this.coverImageBytes,
    this.coverImageFileName,
    this.coverImageMimeType,
  });

  final String title;
  final String description;
  final String createdBy;
  final List<ActivityPathPageDraft> pages;
  final String? coverImageUrl;
  final Uint8List? coverImageBytes;
  final String? coverImageFileName;
  final String? coverImageMimeType;
}
