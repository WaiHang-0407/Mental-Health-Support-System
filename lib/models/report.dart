class Report {
  final String? id;
  final String reporterId;
  final String? postId;
  final String? commentId;
  final String reason;
  final String status;
  final String? reviewedBy;
  final DateTime? createdAt;

  Report({
    this.id,
    required this.reporterId,
    this.postId,
    this.commentId,
    required this.reason,
    this.status = 'pending',
    this.reviewedBy,
    this.createdAt,
  });

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'],
      reporterId: map['reporter_id'],
      postId: map['post_id'],
      commentId: map['comment_id'],
      reason: map['reason'],
      status: map['status'] ?? 'pending',
      reviewedBy: map['reviewed_by'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'reporter_id': reporterId,
      if (postId != null) 'post_id': postId,
      if (commentId != null) 'comment_id': commentId,
      'reason': reason,
      'status': status,
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
