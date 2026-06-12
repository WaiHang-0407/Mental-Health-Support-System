class ChatMessage {
  final String id;
  final String sessionId;
  final String role;
  final String content;
  final String? imageUrl;
  final bool isDeleted;
  final bool isHidden;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.imageUrl,
    this.isDeleted = false,
    this.isHidden = false,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      sessionId: map['session_id'],
      role: map['role'],
      content: map['content'],
      imageUrl: map['image_url'],
      isDeleted: map['is_deleted'] ?? false,
      isHidden: map['is_hidden'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'role': role,
      'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}