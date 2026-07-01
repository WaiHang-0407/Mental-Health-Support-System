class ListenerModel {
  final String id;
  final String name;
  final String? bio;
  final String? profileUrl;
  final double rating;
  final int totalSessions;
  final String status;
  final DateTime? createdAt;
  final String? introductionMessage;

  ListenerModel({
    required this.id,
    required this.name,
    this.bio,
    this.profileUrl,
    required this.rating,
    required this.totalSessions,
    required this.status,
    this.createdAt,
    this.introductionMessage,
  });

  factory ListenerModel.fromMap(Map<String, dynamic> map) {
    return ListenerModel(
      id: map['id'],
      name: map['name'],
      bio: map['bio'],
      profileUrl: map['profile_url'],
      rating: map['rating'] == null
          ? 5.0
          : double.parse(map['rating'].toString()),
      totalSessions: map['total_sessions'] ?? 0,
      status: map['status'] ?? 'available',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      introductionMessage: map['introduction_message'],
    );
  }
}
