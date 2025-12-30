import '../models/message_model.dart';
import 'base_provider.dart';

/// Model for a conversation
class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.propertyId,
    required this.participantIds,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.propertyName,
    this.propertyImageUrl,
  });

  final String id;
  final int propertyId;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final String? propertyName;
  final String? propertyImageUrl;

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    final participantList = map['participant_ids'] ?? map['participantIds'];
    return ConversationModel(
      id: map['id']?.toString() ?? '',
      propertyId: _parseInt(map['property_id'] ?? map['propertyId']) ?? 0,
      participantIds: participantList is List
          ? participantList.map((e) => e.toString()).toList()
          : <String>[],
      lastMessage: _asString(map['last_message'] ?? map['lastMessage']) ?? '',
      lastMessageAt: _parseDateTime(
              map['last_message_at'] ?? map['lastMessageAt']) ??
          DateTime.now(),
      unreadCount: _parseInt(map['unread_count'] ?? map['unreadCount']) ?? 0,
      propertyName: _asString(map['property_name'] ?? map['propertyName']),
      propertyImageUrl:
          _asString(map['property_image_url'] ?? map['propertyImageUrl']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'property_id': propertyId,
        'participant_ids': participantIds,
        'last_message': lastMessage,
        'last_message_at': lastMessageAt.toIso8601String(),
        'unread_count': unreadCount,
        'property_name': propertyName,
        'property_image_url': propertyImageUrl,
      };

  // Helper methods for safe type conversion
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class MessageProvider extends BaseProvider {
  static const String _basePath = '/api/v1/messages';

  /// Get all conversations for the current user
  Future<List<ConversationModel>> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await getWithRetry<Map<String, dynamic>>(
      '$_basePath/conversations',
      query: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    return handleResponse(res, (data) {
      if (data == null) return <ConversationModel>[];
      final dataMap = data as Map<String, dynamic>;
      final items =
          (dataMap['data'] ?? dataMap['conversations'] ?? dataMap) as List?;
      if (items == null) return <ConversationModel>[];
      return items
          .whereType<Map<String, dynamic>>()
          .map(ConversationModel.fromMap)
          .toList();
    });
  }

  /// Get messages for a specific conversation
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 20,
  }) async {
    final res = await getWithRetry<Map<String, dynamic>>(
      '$_basePath/conversations/$conversationId',
      query: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    return handleResponse(res, (data) {
      if (data == null) return <MessageModel>[];
      final dataMap = data as Map<String, dynamic>;
      final items = (dataMap['data'] ?? dataMap['messages'] ?? dataMap) as List?;
      if (items == null) return <MessageModel>[];
      return items
          .whereType<Map<String, dynamic>>()
          .map(MessageModel.fromMap)
          .toList();
    });
  }

  /// Send a message in a conversation
  Future<MessageModel> sendMessage(
    String conversationId,
    String content,
  ) async {
    final res = await postWithRetry<Map<String, dynamic>>(
      '$_basePath/conversations/$conversationId',
      {
        'content': content,
      },
    );

    return handleResponse(res, (data) {
      if (data == null) {
        throw Exception('Failed to send message: empty response');
      }
      final dataMap = data as Map<String, dynamic>;
      final messageData =
          (dataMap['data'] ?? dataMap['message'] ?? dataMap) as Map<String, dynamic>;
      return MessageModel.fromMap(messageData);
    });
  }

  /// Mark a conversation as read
  Future<void> markAsRead(String conversationId) async {
    final res = await postWithRetry<Map<String, dynamic>>(
      '$_basePath/conversations/$conversationId/read',
      <String, dynamic>{},
    );

    handleResponse(res, (_) => null);
  }

  /// Start a new conversation with a property host
  Future<ConversationModel> startConversation({
    required int propertyId,
    required String initialMessage,
  }) async {
    final res = await postWithRetry<Map<String, dynamic>>(
      '$_basePath/conversations',
      {
        'property_id': propertyId,
        'message': initialMessage,
      },
    );

    return handleResponse(res, (data) {
      if (data == null) {
        throw Exception('Failed to start conversation: empty response');
      }
      final dataMap = data as Map<String, dynamic>;
      final conversationData =
          (dataMap['data'] ?? dataMap['conversation'] ?? dataMap) as Map<String, dynamic>;
      return ConversationModel.fromMap(conversationData);
    });
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    final res = await delete<Map<String, dynamic>>('$_basePath/$messageId');
    handleResponse(res, (_) => null);
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    final res = await getWithRetry<Map<String, dynamic>>('$_basePath/unread-count');

    return handleResponse(res, (data) {
      if (data == null) return 0;
      final dataMap = data as Map<String, dynamic>;
      final count = dataMap['count'] ?? dataMap['unread_count'];
      if (count is int) return count;
      if (count is num) return count.toInt();
      return 0;
    });
  }
}
