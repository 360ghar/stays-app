import '../../utils/helpers/json_helpers.dart';

/// One chat message of a booking: `{id, sender_id, body, created_at}`.
///
/// The chat of a stay is the thread of its booking. The guest and the host
/// are the only two senders.
class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.pending = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
    id: JsonHelpers.getInt(map['id']) ?? 0,
    senderId: JsonHelpers.getInt(map['sender_id']),
    body: JsonHelpers.getStringOrDefault(map['body']),
    createdAt:
        JsonHelpers.getDateTime(map['created_at']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  final int id;

  /// The sender's backend user id. Null for a sender that was removed.
  final int? senderId;
  final String body;

  /// UTC instant. Convert to local time only for display.
  final DateTime createdAt;

  /// True for a message that was added on screen and is not saved yet.
  final bool pending;

  bool isMine(int currentUserId) => senderId == currentUserId;
}
