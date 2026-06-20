import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stays_app/app/data/models/message_model.dart';
import 'package:stays_app/app/data/providers/message_provider.dart';

class MessageRepository {
  MessageRepository({MessageProvider? provider})
    : _provider = provider ?? MessageProvider();

  final MessageProvider _provider;

  Future<List<ConversationModel>> listConversations({int limit = 50}) =>
      _provider.listConversations(limit: limit);

  Future<List<MessageModel>> listMessages(
    String conversationId, {
    int limit = 100,
  }) => _provider.listMessages(conversationId, limit: limit);

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
  }) => _provider.sendMessage(conversationId: conversationId, content: content);

  Future<void> markRead(String conversationId) =>
      _provider.markRead(conversationId);

  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required void Function(MessageModel) onMessage,
    void Function(MessageModel)? onMessageUpdate,
  }) => _provider.subscribeToMessages(
    conversationId: conversationId,
    onMessage: onMessage,
    onMessageUpdate: onMessageUpdate,
  );

  Future<ConversationModel> ensureConversation({
    required int propertyId,
    required String hostId,
    int? bookingId,
  }) => _provider.ensureConversation(
    propertyId: propertyId,
    hostId: hostId,
    bookingId: bookingId,
  );
}
