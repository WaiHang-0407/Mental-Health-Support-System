class UserActivityLog {
  final String? id;
  final String patientId;
  final String action;
  final String? targetType;
  final String? targetId;
  final DateTime createdAt;

  UserActivityLog({
    this.id,
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
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'action': action,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'patient_id': patientId,
      'action': action,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
    };
  }

  String get displayAction {
    switch (action) {
      case 'post_created':
        return 'You created a post';
      case 'post_deleted':
        return 'You deleted a post';
      case 'post_archived':
        return 'You archived a post';
      case 'post_unarchived':
        return 'You restored a post';
      case 'post_saved':
        return 'You saved a post';
      case 'post_unsaved':
        return 'You removed a saved post';
      case 'post_liked':
        return 'You liked a post';
      case 'post_reported':
        return 'You reported a post';
      case 'comment_created':
        return 'You commented on a post';
      case 'comment_replied':
        return 'You replied to a comment';
      case 'comment_deleted':
        return 'You deleted a comment';
      case 'comment_reported':
        return 'You reported a comment';
      case 'activity_registered':
        return 'You registered for an activity';
      case 'activity_cancelled':
        return 'You cancelled an activity registration';
      case 'profile_updated':
        return 'You updated your profile';
      case 'personalization_updated':
        return 'You updated your preferences';
      case 'avatar_updated':
        return 'You changed your profile picture';
      case 'chat_started':
        return 'You started an AI companion chat';
      case 'activity_path_selected':
        return 'You started an activity path';
      default:
        return action.replaceAll('_', ' ');
    }
  }
}
