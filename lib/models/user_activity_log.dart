// models/user_activity_log.dart
class UserActivityLog {
  final String id;
  final String patientId;
  final String action;
  final String? targetType;
  final String? targetId;
  final DateTime createdAt;

  UserActivityLog({
    required this.id,
    required this.patientId,
    required this.action,
    this.targetType,
    this.targetId,
    required this.createdAt,
  });

  factory UserActivityLog.fromMap(Map<String, dynamic> map) {
    return UserActivityLog(
      id: map['id'],
      patientId: map['patient_id'],
      action: map['action'],
      targetType: map['target_type'],
      targetId: map['target_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String get displayAction {
    switch (action) {
      case 'post_created': return '📝 Created a post';
      case 'post_liked': return '❤️ Liked a post';
      case 'post_saved': return '🔖 Saved a post';
      case 'post_deleted': return '🗑️ Deleted a post';
      case 'post_reported': return '🚩 Reported a post';
      case 'comment_created': return '💬 Commented on a post';
      case 'activity_registered': return '✅ Registered for an activity';
      case 'activity_cancelled': return '❌ Cancelled activity registration';
      default: return action;
    }
  }
}