// models/post.dart
class Post {
  final String id;
  final String patientId;
  final String content;
  final List<String> imageUrls;
  final bool isDeleted;
  final bool isArchived;
  final String? deletedBy;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isSaved;
  final String? authorName;
  final String? authorRole;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.patientId,
    required this.content,
    this.imageUrls = const [],
    this.isDeleted = false,
    this.isArchived = false,
    this.deletedBy,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.authorName,
    this.authorRole,
    required this.createdAt,
  });

  factory Post.fromMap(
    Map<String, dynamic> map, {
    bool isLiked = false,
    bool isSaved = false,
  }) {
    final rawImages = map['image_urls'];
    List<String> imageUrls = [];
    if (rawImages != null && rawImages.toString().isNotEmpty) {
      imageUrls = rawImages.toString().split(',');
    }

    return Post(
      id: map['id'],
      patientId: map['patient_id'],
      content: map['content'],
      imageUrls: imageUrls,
      isDeleted: map['is_deleted'] ?? false,
      isArchived: map['is_archived'] ?? false,
      deletedBy: map['deleted_by'],
      likeCount: map['like_count'] ?? 0,
      commentCount: map['comment_count'] ?? 0,
      isLiked: isLiked,
      isSaved: isSaved,
      authorName: map['author_name'],
      authorRole: map['author_role'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'content': content,
      'image_urls': imageUrls.join(','),
      'is_deleted': isDeleted,
      'is_archived': isArchived,
      if (deletedBy != null) 'deleted_by': deletedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'patient_id': patientId,
      'content': content,
      'image_urls': imageUrls.join(','),
    };
  }
}
