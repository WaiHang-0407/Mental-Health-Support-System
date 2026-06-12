// models/post.dart
class Post {
  final String id;
  final String patientId;
  final String content;
  final List<String> imageUrls; // 👈 changed from single to list
  final bool isDeleted;
  final bool isArchived;        // 👈 added
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isSaved;
  final String? authorName;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.patientId,
    required this.content,
    this.imageUrls = const [],
    this.isDeleted = false,
    this.isArchived = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.authorName,
    required this.createdAt,
  });

  factory Post.fromMap(Map<String, dynamic> map,
      {bool isLiked = false, bool isSaved = false}) {
    // image_urls stored as comma-separated string in DB
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
      likeCount: map['like_count'] ?? 0,
      commentCount: map['comment_count'] ?? 0,
      isLiked: isLiked,
      isSaved: isSaved,
      authorName: map['author_name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}