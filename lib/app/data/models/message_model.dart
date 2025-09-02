class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        id: map['id']?.toString() ?? '',
        conversationId: map['conversationId']?.toString() ?? '',
        senderId: map['senderId']?.toString() ?? '',
        content: map['content'] as String? ?? '',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };
}

