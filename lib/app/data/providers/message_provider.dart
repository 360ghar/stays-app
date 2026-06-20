import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stays_app/app/data/models/message_model.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

/// Talks to the Supabase `conversations` and `messages` tables (RLS-protected)
/// and subscribes to Realtime inserts for live messaging.
class MessageProvider {
  SupabaseClient get _client => Supabase.instance.client;

  String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Not authenticated');
    }
    return id;
  }

  /// List conversations where the current user is guest or host.
  Future<List<ConversationModel>> listConversations({int limit = 50}) async {
    final userId = _currentUserId;
    final response = await _client
        .from('conversations')
        .select()
        .or('guest_id.eq.$userId,host_id.eq.$userId')
        .order('last_message_at', ascending: false, nullsFirst: false)
        .limit(limit);
    return (response as List)
        .whereType<Map<String, dynamic>>()
        .map(ConversationModel.fromMap)
        .toList();
  }

  /// Fetch recent messages for a conversation.
  Future<List<MessageModel>> listMessages(
    String conversationId, {
    int limit = 100,
  }) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .limit(limit);
    return (response as List)
        .whereType<Map<String, dynamic>>()
        .map(MessageModel.fromMap)
        .toList();
  }

  /// Insert a new message. Returns the inserted row.
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final userId = _currentUserId;
    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'content': content,
        })
        .select()
        .limit(1)
        .single();
    // Best-effort bump of conversation last_message_at.
    try {
      await _client
          .from('conversations')
          .update({
            'last_message': content,
            'last_message_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', conversationId);
    } catch (e) {
      AppLogger.warning('Failed to bump conversation last_message_at: $e');
    }
    return MessageModel.fromMap(response);
  }

  /// Mark all unread messages in a conversation as read for the current user.
  Future<void> markRead(String conversationId) async {
    final userId = _currentUserId;
    try {
      await _client
          .from('messages')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .isFilter('read_at', null);
    } catch (e) {
      AppLogger.warning('Failed to mark messages read: $e');
    }
  }

  /// Subscribe to realtime inserts and updates on a conversation.
  /// [onMessage] fires for new inserts; [onMessageUpdate] fires when an
  /// existing message row changes (e.g. `read_at` is set by the recipient).
  /// Returns a [RealtimeChannel] the caller must `.unsubscribe()` on cleanup.
  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required void Function(MessageModel) onMessage,
    void Function(MessageModel)? onMessageUpdate,
  }) {
    final channel = _client.channel('messages:$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            try {
              onMessage(MessageModel.fromMap(newRecord));
            } catch (e) {
              AppLogger.warning('Failed to parse realtime message: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            if (onMessageUpdate == null) return;
            final newRecord = payload.newRecord;
            try {
              onMessageUpdate(MessageModel.fromMap(newRecord));
            } catch (e) {
              AppLogger.warning('Failed to parse realtime update: $e');
            }
          },
        )
        .subscribe();
    return channel;
  }

  /// Create a conversation between the current user and a host for a property
  /// (idempotent: returns an existing one if present).
  Future<ConversationModel> ensureConversation({
    required int propertyId,
    required String hostId,
    int? bookingId,
  }) async {
    final userId = _currentUserId;
    // Try to find an existing one first.
    final existing = await _client
        .from('conversations')
        .select()
        .eq('property_id', propertyId)
        .eq('guest_id', userId)
        .eq('host_id', hostId)
        .limit(1);
    if (existing.isNotEmpty) {
      return ConversationModel.fromMap(existing.first);
    }
    final response = await _client
        .from('conversations')
        .insert({
          'property_id': propertyId,
          if (bookingId != null) 'booking_id': bookingId,
          'guest_id': userId,
          'host_id': hostId,
        })
        .select()
        .limit(1)
        .single();
    return ConversationModel.fromMap(response);
  }
}
