import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/app/data/models/message_model.dart';
import 'package:stays_app/app/data/repositories/booking_repository.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/core/providers/data_providers.dart';

/// Longest message the backend takes, after trimming.
const int maxMessageLength = 2000;

/// How often an open chat reads the newest page. The backend has no push
/// channel for booking chat.
const Duration chatPollInterval = Duration(seconds: 10);

class ChatUiState {
  const ChatUiState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.isLoadingOlder = false,
    this.error = '',
    this.title = 'Chat',
    this.myUserId,
    this.olderCursor,
    this.hasOlder = false,
  });

  /// Oldest first. A message that is not saved yet has `pending` set.
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final bool isLoadingOlder;
  final String error;
  final String title;

  /// The guest of the booking, which is the signed-in user.
  final int? myUserId;

  /// Cursor of the next older page.
  final String? olderCursor;
  final bool hasOlder;

  ChatUiState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isLoadingOlder,
    String? error,
    String? title,
    int? myUserId,
    String? olderCursor,
    bool? hasOlder,
  }) {
    return ChatUiState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      error: error ?? this.error,
      title: title ?? this.title,
      myUserId: myUserId ?? this.myUserId,
      olderCursor: olderCursor ?? this.olderCursor,
      hasOlder: hasOlder ?? this.hasOlder,
    );
  }
}

/// Chat of one booking, through `GET|POST /api/v1/bookings/{id}/messages`.
final chatProvider = NotifierProvider.autoDispose
    .family<ChatNotifier, ChatUiState, int>((arg) => ChatNotifier(arg));

class ChatNotifier extends Notifier<ChatUiState> {
  ChatNotifier(this.bookingId);

  final int bookingId;

  Timer? _poll;
  int _pendingCounter = 0;

  BookingRepository get _repo => ref.watch(bookingRepositoryProvider);

  @override
  ChatUiState build() {
    ref.onDispose(() {
      _poll?.cancel();
      _poll = null;
    });
    unawaited(Future(_bootstrap));
    return const ChatUiState();
  }

  Future<void> _bootstrap() async {
    final repo = _repo;
    try {
      // The booking tells who the signed-in guest is, so each bubble can be
      // placed. The page comes newest first.
      final (booking, page) = await (
        repo.getBooking(bookingId),
        repo.listMessages(bookingId),
      ).wait;
      state = state.copyWith(
        messages: page.items.reversed.toList(),
        isLoading: false,
        error: '',
        title: booking.displayTitle,
        myUserId: booking.userId,
        olderCursor: page.nextCursor,
        hasOlder: page.hasNextPage,
      );
      _poll ??= Timer.periodic(chatPollInterval, (_) => unawaited(_refresh()));
    } catch (e, s) {
      AppLogger.error('Chat: load failed', e, s);
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load messages. Pull to retry.',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: '');
    await _bootstrap();
  }

  /// Reads the newest page and appends the messages that are new.
  Future<void> _refresh() async {
    try {
      final page = await _repo.listMessages(bookingId);
      final known = {for (final m in state.messages) m.id};
      final fresh = page.items.reversed.where((m) => !known.contains(m.id));
      if (fresh.isEmpty) return;
      state = state.copyWith(messages: [...state.messages, ...fresh]);
    } catch (e) {
      // A poll that fails is retried on the next tick.
      AppLogger.warning('Chat: refresh failed: $e');
    }
  }

  /// Reads the next older page and puts it before the loaded messages.
  Future<void> loadOlder() async {
    final cursor = state.olderCursor;
    if (!state.hasOlder || cursor == null || state.isLoadingOlder) return;
    state = state.copyWith(isLoadingOlder: true);
    try {
      final page = await _repo.listMessages(bookingId, cursor: cursor);
      final known = {for (final m in state.messages) m.id};
      final older = page.items.reversed.where((m) => !known.contains(m.id));
      state = state.copyWith(
        messages: [...older, ...state.messages],
        isLoadingOlder: false,
        olderCursor: page.nextCursor,
        hasOlder: page.hasNextPage,
      );
    } catch (e, s) {
      AppLogger.error('Chat: loadOlder failed', e, s);
      state = state.copyWith(
        isLoadingOlder: false,
        error: 'Could not load earlier messages.',
      );
    }
  }

  Future<void> send(String content) async {
    final text = content.trim();
    // While the first page loads, a sent message would be replaced by it.
    if (text.isEmpty || state.isSending || state.isLoading) return;
    if (text.length > maxMessageLength) {
      state = state.copyWith(
        error: 'A message can have at most $maxMessageLength characters.',
      );
      return;
    }
    final repo = _repo;
    state = state.copyWith(isSending: true, error: '');
    final optimistic = MessageModel(
      id: -(++_pendingCounter),
      senderId: state.myUserId,
      body: text,
      createdAt: DateTime.now().toUtc(),
      pending: true,
    );
    state = state.copyWith(messages: [...state.messages, optimistic]);
    try {
      final sent = await repo.sendMessage(bookingId, text);
      // A poll may have added the saved message already.
      final alreadySaved = state.messages.any((m) => m.id == sent.id);
      final next = [
        for (final m in state.messages)
          if (m.id != optimistic.id) m else if (!alreadySaved) sent,
      ];
      state = state.copyWith(messages: next);
    } catch (e, s) {
      AppLogger.error('Chat: send failed', e, s);
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != optimistic.id).toList(),
        error: e is ApiException && e.message.isNotEmpty
            ? e.message
            : 'Message could not be sent. Please try again.',
      );
    } finally {
      state = state.copyWith(isSending: false);
    }
  }
}
