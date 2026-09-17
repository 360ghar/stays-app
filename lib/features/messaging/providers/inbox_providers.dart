import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;

import 'package:stays_app/app/data/models/message_model.dart';
import 'package:stays_app/app/data/repositories/message_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class InboxUiState {
  const InboxUiState({
    this.conversations = const [],
    this.isLoading = true,
    this.error = '',
  });
  final List<ConversationModel> conversations;
  final bool isLoading;
  final String error;

  InboxUiState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return InboxUiState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final inboxProvider = NotifierProvider<InboxNotifier, InboxUiState>(
  InboxNotifier.new,
);

class InboxNotifier extends Notifier<InboxUiState> {
  @override
  InboxUiState build() {
    unawaited(Future(() => load()));
    return const InboxUiState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: '');
    if (!Get.isRegistered<MessageRepository>()) {
      state = state.copyWith(
        isLoading: false,
        error: 'Inbox service unavailable.',
      );
      return;
    }
    try {
      final list = await Get.find<MessageRepository>().listConversations();
      list.sort(
        (a, b) => (b.lastMessageAt ?? b.createdAt).compareTo(
          a.lastMessageAt ?? a.createdAt,
        ),
      );
      state = InboxUiState(conversations: list);
    } catch (e, s) {
      AppLogger.error('Inbox v2: load failed', e, s);
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load conversations. Pull to retry.',
      );
    }
  }

  Future<void> refresh() => load();
}
