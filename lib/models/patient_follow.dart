class PatientFollow {
  final String? id;
  final String followerId;
  final String followingId;
  final DateTime? createdAt;

  PatientFollow({
    this.id,
    required this.followerId,
    required this.followingId,
    this.createdAt,
  });

  factory PatientFollow.fromMap(Map<String, dynamic> map) {
    return PatientFollow(
      id: map['id'],
      followerId: map['follower_id'],
      followingId: map['following_id'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'follower_id': followerId,
      'following_id': followingId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
