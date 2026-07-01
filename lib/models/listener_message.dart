class ListenerMessageModel {
  final String id;
  final String conversationId;
  final String senderType;
  final String message;
  final DateTime? createdAt;

  ListenerMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.message,
    this.createdAt,
  });

  factory ListenerMessageModel.fromMap(Map<String, dynamic> map) {
    return ListenerMessageModel(
      id: map['id'],
      conversationId: map['conversation_id'],
      senderType: map['sender_type'],
      message: map['message'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }
}
