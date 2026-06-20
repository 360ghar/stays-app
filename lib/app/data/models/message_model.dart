class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
    id: map['id']?.toString() ?? '',
    conversationId:
        map['conversation_id']?.toString() ??
        map['conversationId']?.toString() ??
        '',
    senderId: map['sender_id']?.toString() ?? map['senderId']?.toString() ?? '',
    content: map['content'] as String? ?? '',
    createdAt:
        DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    readAt: (map['read_at'] == null || map['read_at'] == '')
        ? null
        : DateTime.tryParse(map['read_at'].toString()),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    if (readAt != null) 'read_at': readAt!.toIso8601String(),
  };

  bool isMine(String currentUserId) => senderId == currentUserId;

  bool get isRead => readAt != null;
}

/// A conversation summary for the inbox list.
class ConversationModel {
  final String id;
  final int? propertyId;
  final int? bookingId;
  final String guestId;
  final String hostId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  const ConversationModel({
    required this.id,
    this.propertyId,
    this.bookingId,
    required this.guestId,
    required this.hostId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) =>
      ConversationModel(
        id: map['id']?.toString() ?? '',
        propertyId: (map['property_id'] as num?)?.toInt(),
        bookingId: (map['booking_id'] as num?)?.toInt(),
        guestId: map['guest_id']?.toString() ?? '',
        hostId: map['host_id']?.toString() ?? '',
        lastMessage: map['last_message'] as String?,
        lastMessageAt:
            (map['last_message_at'] == null || map['last_message_at'] == '')
            ? null
            : DateTime.tryParse(map['last_message_at'].toString()),
        createdAt:
            DateTime.tryParse(map['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
