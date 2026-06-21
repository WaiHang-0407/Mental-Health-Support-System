// models/comment.dart
class Comment {
  final String id;
  final String postId;
  final String patientId;
  final String? parentId;
  final String content;
  final bool isDeleted;
  final String? deletedBy;
  final int likeCount;
  final bool isLiked;
  final String? authorName;
  final List<Comment> replies;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.patientId,
    this.parentId,
    required this.content,
    this.isDeleted = false,
    this.deletedBy,
    this.likeCount = 0,
    this.isLiked = false,
    this.authorName,
    this.replies = const [],
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map, {bool isLiked = false}) {
    return Comment(
      id: map['id'],
      postId: map['post_id'],
      patientId: map['patient_id'],
      parentId: map['parent_id'],
      content: map['content'],
      isDeleted: map['is_deleted'] ?? false,
      deletedBy: map['deleted_by'],
      likeCount: map['like_count'] ?? 0,
      isLiked: isLiked,
      authorName: map['author_name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'patient_id': patientId,
      if (parentId != null) 'parent_id': parentId,
      'content': content,
      'is_deleted': isDeleted,
      if (deletedBy != null) 'deleted_by': deletedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'post_id': postId,
      'patient_id': patientId,
      if (parentId != null) 'parent_id': parentId,
      'content': content,
    };
  }
}
