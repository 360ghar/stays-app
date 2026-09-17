import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stays_app/app/data/models/message_model.dart';
import 'package:stays_app/app/data/repositories/message_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class ChatUiState {
  const ChatUiState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.error = '',
  });
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final String error;

  ChatUiState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ChatUiState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
    );
  }
}

final chatProvider = NotifierProvider.autoDispose
    .family<ChatNotifier, ChatUiState, String>(ChatNotifier.new);

class ChatNotifier extends AutoDisposeFamilyNotifier<ChatUiState, String> {
  RealtimeChannel? _channel;

  String get _me {
    try {
      return Supabase.instance.client.auth.currentUser?.id ?? '';
    } catch (_) {
      return '';
    }
  }

  MessageRepository? get _repo => Get.isRegistered<MessageRepository>()
      ? Get.find<MessageRepository>()
      : null;

  @override
  ChatUiState build(String conversationId) {
    ref.onDispose(() {
      unawaited(_channel?.unsubscribe());
      _channel = null;
    });
    unawaited(Future(() => _bootstrap(conversationId)));
    return const ChatUiState();
  }

  Future<void> _bootstrap(String conversationId) async {
    final repo = _repo;
    if (repo == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Chat service unavailable.',
      );
      return;
    }
    try {
      final list = await repo.listMessages(conversationId);
      state = state.copyWith(messages: list, isLoading: false);
      unawaited(repo.markRead(conversationId));
      _channel = repo.subscribeToMessages(
        conversationId: conversationId,
        onMessage: (msg) {
          final exists = state.messages.any((m) => m.id == msg.id);
          if (!exists) {
            state = state.copyWith(messages: [...state.messages, msg]);
          }
          if (msg.senderId != _me) {
            unawaited(repo.markRead(conversationId));
          }
        },
        onMessageUpdate: (updated) {
          final index = state.messages.indexWhere((m) => m.id == updated.id);
          if (index != -1) {
            final next = [...state.messages];
            next[index] = updated;
            state = state.copyWith(messages: next);
          }
        },
      );
    } catch (e, s) {
      AppLogger.error('Chat v2: load failed', e, s);
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load messages. Pull to retry.',
      );
    }
  }

  Future<void> refresh(String conversationId) => _bootstrap(conversationId);

  Future<void> send(String conversationId, String content) async {
    final text = content.trim();
    final repo = _repo;
    if (text.isEmpty || state.isSending || repo == null) return;
    state = state.copyWith(isSending: true);
    final optimistic = MessageModel(
      id: 'optimistic-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: _me,
      content: text,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, optimistic]);
    try {
      final sent = await repo.sendMessage(
        conversationId: conversationId,
        content: text,
      );
      final next = [...state.messages];
      final idx = next.indexWhere((m) => m.id == optimistic.id);
      if (idx != -1) {
        next[idx] = sent;
      } else {
        next.add(sent);
      }
      state = state.copyWith(messages: next);
    } catch (e, s) {
      AppLogger.error('Chat v2: send failed', e, s);
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != optimistic.id).toList(),
        error: 'Message could not be sent. Please try again.',
      );
    } finally {
      state = state.copyWith(isSending: false);
    }
  }
}
