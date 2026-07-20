import 'admin_community_post.dart';

class AdminActivityLog {
  const AdminActivityLog({
    this.id,
    required this.adminId,
    required this.action,
    this.targetType,
    this.targetId,
    this.createdAt,
  });

  final String? id;
  final String adminId;
  final String action;
  final String? targetType;
  final String? targetId;
  final DateTime? createdAt;

  factory AdminActivityLog.fromJson(Map<String, dynamic> json) {
    return AdminActivityLog(
      id: json['id']?.toString(),
      adminId: json['admin_id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      targetType: json['target_type'] as String?,
      targetId: json['target_id']?.toString(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'admin_id': adminId,
      'action': action,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
    };
  }
}

class AdminActivityLogTargetDetails {
  const AdminActivityLogTargetDetails({
    required this.title,
    required this.targetType,
    required this.targetId,
    this.fields = const {},
    this.postDetails,
    this.comment,
    this.relatedPost,
  });

  final String title;
  final String targetType;
  final String targetId;
  final Map<String, String> fields;
  final AdminCommunityPostDetails? postDetails;
  final AdminCommunityComment? comment;
  final AdminCommunityPost? relatedPost;

  bool get hasRichPost => postDetails != null;
  bool get hasComment => comment != null;
}
