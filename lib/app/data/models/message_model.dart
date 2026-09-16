import '../../utils/helpers/json_helpers.dart';

class MessageModel {
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
    content: JsonHelpers.getStringOrDefault(map['content']),
    createdAt:
        JsonHelpers.getDateTime(map['created_at'] ?? map['createdAt']) ??
        DateTime.now(),
    readAt: (map['read_at'] == null || map['read_at'] == '')
        ? null
        : DateTime.tryParse(map['read_at'].toString()),
  );
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;

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
  const ConversationModel({
    required this.id,
    required this.guestId,
    required this.hostId,
    required this.createdAt,
    this.propertyId,
    this.bookingId,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) =>
      ConversationModel(
        id: map['id']?.toString() ?? '',
        propertyId: JsonHelpers.getInt(map['property_id']),
        bookingId: JsonHelpers.getInt(map['booking_id']),
        guestId: map['guest_id']?.toString() ?? '',
        hostId: map['host_id']?.toString() ?? '',
        lastMessage: JsonHelpers.getString(map['last_message']),
        lastMessageAt:
            (map['last_message_at'] == null || map['last_message_at'] == '')
            ? null
            : DateTime.tryParse(map['last_message_at'].toString()),
        createdAt: JsonHelpers.getDateTime(map['created_at']) ?? DateTime.now(),
      );
  final String id;
  final int? propertyId;
  final int? bookingId;
  final String guestId;
  final String hostId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
}
