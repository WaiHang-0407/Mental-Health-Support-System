class ActivityPath {
  final String id;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final bool isDeleted;
  final bool isArchived;
  final DateTime createdAt;
  final bool isSelected;
  final int currentPageNumber;
  final int completedPageCount;
  final DateTime? lastOpenedAt;
  final DateTime? completedAt;
  final bool isSaved;
  final DateTime? savedAt;
  final List<ActivityPathPage> pages;

  const ActivityPath({
    required this.id,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.isDeleted = false,
    this.isArchived = false,
    required this.createdAt,
    this.isSelected = false,
    this.currentPageNumber = 1,
    this.completedPageCount = 0,
    this.lastOpenedAt,
    this.completedAt,
    this.isSaved = false,
    this.savedAt,
    this.pages = const [],
  });

  factory ActivityPath.fromMap(
    Map<String, dynamic> map, {
    List<ActivityPathPage> pages = const [],
    ActivityPathProgress? progress,
  }) {
    return ActivityPath(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      coverImageUrl: map['cover_image_url'] as String?,
      isDeleted: map['is_deleted'] as bool? ?? false,
      isArchived: map['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      isSelected: progress?.isStarted ?? false,
      currentPageNumber: progress?.currentPageNumber ?? 1,
      completedPageCount: progress?.completedPageCount ?? 0,
      lastOpenedAt: progress?.lastOpenedAt,
      completedAt: progress?.completedAt,
      isSaved: progress?.isSaved ?? false,
      savedAt: progress?.savedAt,
      pages: pages,
    );
  }

  int get safeCurrentPageNumber {
    if (pages.isEmpty) return 1;
    return currentPageNumber.clamp(1, pages.length);
  }

  double get progressFraction {
    if (pages.isEmpty) return 0;
    return (completedPageCount.clamp(0, pages.length)) / pages.length;
  }

  bool get isCompleted => completedAt != null || progressFraction >= 1;

  ActivityPath copyWith({
    List<ActivityPathPage>? pages,
    bool? isSelected,
    int? currentPageNumber,
    int? completedPageCount,
    DateTime? lastOpenedAt,
    DateTime? completedAt,
    bool? isSaved,
    DateTime? savedAt,
  }) {
    return ActivityPath(
      id: id,
      title: title,
      description: description,
      coverImageUrl: coverImageUrl,
      isDeleted: isDeleted,
      isArchived: isArchived,
      createdAt: createdAt,
      isSelected: isSelected ?? this.isSelected,
      currentPageNumber: currentPageNumber ?? this.currentPageNumber,
      completedPageCount: completedPageCount ?? this.completedPageCount,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      completedAt: completedAt ?? this.completedAt,
      isSaved: isSaved ?? this.isSaved,
      savedAt: savedAt ?? this.savedAt,
      pages: pages ?? this.pages,
    );
  }
}

class ActivityPathProgress {
  final String activityPathId;
  final int currentPageNumber;
  final int completedPageCount;
  final DateTime? lastOpenedAt;
  final DateTime? completedAt;
  final bool isSaved;
  final DateTime? savedAt;

  const ActivityPathProgress({
    required this.activityPathId,
    this.currentPageNumber = 1,
    this.completedPageCount = 0,
    this.lastOpenedAt,
    this.completedAt,
    this.isSaved = false,
    this.savedAt,
  });

  bool get isStarted {
    return lastOpenedAt != null || completedPageCount > 0 || completedAt != null;
  }

  factory ActivityPathProgress.fromMap(Map<String, dynamic> map) {
    return ActivityPathProgress(
      activityPathId: map['activity_path_id'] as String,
      currentPageNumber: map['current_page_number'] as int? ?? 1,
      completedPageCount: map['completed_page_count'] as int? ?? 0,
      lastOpenedAt: map['last_opened_at'] != null
          ? DateTime.parse(map['last_opened_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      isSaved: map['is_saved'] as bool? ?? false,
      savedAt: map['saved_at'] != null
          ? DateTime.parse(map['saved_at'] as String)
          : null,
    );
  }
}

class ActivityPathPage {
  final String id;
  final String activityPathId;
  final int pageNumber;
  final String title;
  final String body;
  final List<ActivityPathImage> images;

  const ActivityPathPage({
    required this.id,
    required this.activityPathId,
    required this.pageNumber,
    required this.title,
    required this.body,
    this.images = const [],
  });

  factory ActivityPathPage.fromMap(
    Map<String, dynamic> map, {
    List<ActivityPathImage> images = const [],
  }) {
    return ActivityPathPage(
      id: map['id'] as String,
      activityPathId: map['activity_path_id'] as String,
      pageNumber: map['page_number'] as int? ?? 1,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      images: images,
    );
  }

  ActivityPathPage copyWith({List<ActivityPathImage>? images}) {
    return ActivityPathPage(
      id: id,
      activityPathId: activityPathId,
      pageNumber: pageNumber,
      title: title,
      body: body,
      images: images ?? this.images,
    );
  }
}

class ActivityPathImage {
  final String id;
  final String pageId;
  final String imageUrl;
  final int sortOrder;

  const ActivityPathImage({
    required this.id,
    required this.pageId,
    required this.imageUrl,
    this.sortOrder = 0,
  });

  factory ActivityPathImage.fromMap(Map<String, dynamic> map) {
    return ActivityPathImage(
      id: map['id'] as String,
      pageId: map['page_id'] as String,
      imageUrl: map['image_url'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}
