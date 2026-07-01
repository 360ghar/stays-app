import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/data/models/message_model.dart';
import 'package:stays_app/app/data/repositories/message_repository.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

/// Per-conversation controller. The conversation id is supplied via route
/// parameters (`/chat/:conversationId`).
class ChatController extends BaseController {
  ChatController({required MessageRepository repository})
    : _repository = repository;

  final MessageRepository _repository;

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isSending = false.obs;
  final RxBool isLoading = false.obs;
  final RxString otherUserTyping = ''.obs;

  String _conversationId = '';
  String _currentUserId = '';
  RealtimeChannel? _channel;

  String get currentUserId => _currentUserId;
  String get conversationId => _conversationId;

  @override
  void onInit() {
    super.onInit();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _conversationId = Get.parameters['conversationId'] ?? '';
    if (_conversationId.isEmpty) {
      AppLogger.warning('ChatController initialized without conversationId');
      return;
    }
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    isLoading.value = true;
    try {
      final list = await _repository.listMessages(_conversationId);
      messages.assignAll(list);
      await _repository.markRead(_conversationId);
      _subscribe();
    } catch (e, s) {
      AppLogger.error('Failed to load messages', e, s);
      AppSnackbar.error(
        title: 'Messages',
        message: 'Could not load messages. Pull to retry.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribe() {
    _channel = _repository.subscribeToMessages(
      conversationId: _conversationId,
      onMessage: (msg) {
        // De-dupe optimistic inserts and realtime echoes.
        final exists = messages.any((m) => m.id == msg.id);
        if (!exists) {
          messages.add(msg);
        }
        // Mark read immediately if the new message is from the other party.
        if (msg.senderId != _currentUserId) {
          unawaited(_repository.markRead(_conversationId));
        }
      },
      onMessageUpdate: (updated) {
        // Reflect server-side row updates (e.g. read_at being set by the
        // recipient) so read receipts transition from sent to read.
        final index = messages.indexWhere((m) => m.id == updated.id);
        if (index != -1) {
          messages[index] = updated;
        }
      },
    );
  }

  /// Send a message. Optimistically appends to the list and rolls back on
  /// failure. The send button should be disabled while [isSending] is true.
  Future<void> send(String content) async {
    final text = content.trim();
    if (text.isEmpty || isSending.value) return;
    isSending.value = true;

    final optimistic = MessageModel(
      id: 'optimistic-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: _conversationId,
      senderId: _currentUserId,
      content: text,
      createdAt: DateTime.now(),
    );
    messages.add(optimistic);

    try {
      final sent = await _repository.sendMessage(
        conversationId: _conversationId,
        content: text,
      );
      final idx = messages.indexWhere((m) => m.id == optimistic.id);
      if (idx != -1) {
        messages[idx] = sent;
      } else {
        messages.add(sent);
      }
    } catch (e, s) {
      AppLogger.error('Failed to send message', e, s);
      messages.removeWhere((m) => m.id == optimistic.id);
      AppSnackbar.error(
        title: 'Send failed',
        message: 'Message could not be sent. Please try again.',
      );
    } finally {
      isSending.value = false;
    }
  }

  @override
  void onClose() {
    unawaited(_channel?.unsubscribe());
    _channel = null;
    super.onClose();
  }
}
