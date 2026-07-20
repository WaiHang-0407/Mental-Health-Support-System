class AdminCommunityPost {
  const AdminCommunityPost({
    required this.id,
    required this.patientId,
    required this.content,
    required this.imageUrls,
    required this.isDeleted,
    required this.isArchived,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
  });

  final String id;
  final String patientId;
  final String content;
  final List<String> imageUrls;
  final bool isDeleted;
  final bool isArchived;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;

  String get status {
    if (isDeleted) return 'Deleted';
    if (isArchived) return 'Archived';
    return 'Active';
  }

  String get displayAuthor {
    final value = authorName?.trim();
    return value == null || value.isEmpty ? 'Anonymous' : value;
  }

  factory AdminCommunityPost.fromJson(
    Map<String, dynamic> json, {
    String? authorName,
    String? authorAvatarUrl,
  }) {
    return AdminCommunityPost(
      id: json['id'] as String,
      patientId: json['patient_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrls: _imageUrls(json['image_urls']),
      isDeleted: _parseBool(json['is_deleted']),
      isArchived: _parseBool(json['is_archived']),
      likeCount: (json['post_likes'] as List?)?.first?['count'] as int? ?? 0,
      commentCount: (json['comments'] as List?)?.first?['count'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
    );
  }

  static List<String> _imageUrls(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return const [];
    return text
        .split(',')
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}

class AdminCommunityPostDetails {
  const AdminCommunityPostDetails({
    required this.post,
    required this.likes,
    required this.comments,
  });

  final AdminCommunityPost post;
  final List<AdminCommunityLike> likes;
  final List<AdminCommunityComment> comments;
}

class AdminCommunityLike {
  const AdminCommunityLike({
    required this.id,
    required this.patientId,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
  });

  final String id;
  final String patientId;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;

  String get displayAuthor {
    final value = authorName?.trim();
    return value == null || value.isEmpty ? 'Anonymous' : value;
  }

  factory AdminCommunityLike.fromJson(
    Map<String, dynamic> json, {
    String? authorName,
    String? authorAvatarUrl,
  }) {
    return AdminCommunityLike(
      id: json['id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
    );
  }
}

class AdminCommunityComment {
  const AdminCommunityComment({
    required this.id,
    required this.postId,
    required this.patientId,
    required this.parentId,
    required this.content,
    required this.isDeleted,
    required this.isArchived,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
  });

  final String id;
  final String postId;
  final String patientId;
  final String? parentId;
  final String content;
  final bool isDeleted;
  final bool isArchived;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;

  String get displayAuthor {
    final value = authorName?.trim();
    return value == null || value.isEmpty ? 'Anonymous' : value;
  }

  factory AdminCommunityComment.fromJson(
    Map<String, dynamic> json, {
    String? authorName,
    String? authorAvatarUrl,
  }) {
    return AdminCommunityComment(
      id: json['id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      content: json['content'] as String? ?? '',
      isDeleted: AdminCommunityPost._parseBool(json['is_deleted']),
      isArchived: AdminCommunityPost._parseBool(json['is_archived']),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
    );
  }
}

class AdminCommunityReport {
  const AdminCommunityReport({
    required this.id,
    required this.reporterId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.postId,
    this.commentId,
    this.reviewedBy,
    this.resolutionAction,
    this.resolutionNote,
    this.resolvedAt,
    this.reporterName,
    this.reporterAvatarUrl,
    this.reportedAuthorName,
    this.reportedAuthorAvatarUrl,
    this.reportedContent,
    this.post,
    this.comment,
  });

  final String id;
  final String reporterId;
  final String? postId;
  final String? commentId;
  final String reason;
  final String status;
  final String? reviewedBy;
  final String? resolutionAction;
  final String? resolutionNote;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final String? reporterName;
  final String? reporterAvatarUrl;
  final String? reportedAuthorName;
  final String? reportedAuthorAvatarUrl;
  final String? reportedContent;
  final AdminCommunityPost? post;
  final AdminCommunityComment? comment;

  bool get isPostReport => postId != null && postId!.isNotEmpty;
  String get targetType => isPostReport ? 'Post' : 'Comment';
  String? get reportedUserId => post?.patientId ?? comment?.patientId;
  String? get targetId => postId ?? commentId;

  String get displayReporter {
    final value = reporterName?.trim();
    return value == null || value.isEmpty ? 'Anonymous' : value;
  }

  String get displayReportedAuthor {
    final value = reportedAuthorName?.trim();
    return value == null || value.isEmpty ? 'Unknown author' : value;
  }

  String get displayContent {
    final value = reportedContent?.trim();
    return value == null || value.isEmpty ? 'No content available.' : value;
  }

  factory AdminCommunityReport.fromJson(
    Map<String, dynamic> json, {
    String? reporterName,
    String? reporterAvatarUrl,
    String? reportedAuthorName,
    String? reportedAuthorAvatarUrl,
    String? reportedContent,
    AdminCommunityPost? post,
    AdminCommunityComment? comment,
  }) {
    return AdminCommunityReport(
      id: json['id'] as String? ?? '',
      reporterId: json['reporter_id'] as String? ?? '',
      postId: json['post_id'] as String?,
      commentId: json['comment_id'] as String?,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      reviewedBy: json['reviewed_by'] as String?,
      resolutionAction: json['resolution_action'] as String?,
      resolutionNote: json['resolution_note'] as String?,
      resolvedAt: DateTime.tryParse(json['resolved_at'] as String? ?? ''),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      reporterName: reporterName,
      reporterAvatarUrl: reporterAvatarUrl,
      reportedAuthorName: reportedAuthorName,
      reportedAuthorAvatarUrl: reportedAuthorAvatarUrl,
      reportedContent: reportedContent,
      post: post,
      comment: comment,
    );
  }
}

class AdminUserWarning {
  const AdminUserWarning({
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.description,
  });

  final String userId;
  final String targetType;
  final String targetId;
  final String reason;
  final String? description;

  Map<String, dynamic> toCreateJson(String adminId) {
    return {
      'user_id': userId,
      'admin_id': adminId,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
    };
  }
}
