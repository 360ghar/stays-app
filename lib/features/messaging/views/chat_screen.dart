import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:stays_app/app/data/models/message_model.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/core/ui/async_state.dart';
import 'package:stays_app/features/messaging/providers/chat_providers.dart';

/// V2 chat of one booking. Optimistic send. The open chat reads the newest
/// page every few seconds.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.bookingId, super.key});
  final int bookingId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll
        .animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        )
        .ignore();
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await ref.read(chatProvider(widget.bookingId).notifier).send(text);
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider(widget.bookingId));
    final notifier = ref.read(chatProvider(widget.bookingId).notifier);
    ref.listen(chatProvider(widget.bookingId), (previous, next) {
      // Scroll to the newest message, not when older ones are added on top.
      final grew =
          previous == null ||
          next.messages.isEmpty ||
          previous.messages.isEmpty ||
          next.messages.last.id != previous.messages.last.id;
      if (next.messages.isNotEmpty && grew) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      }
    });
    return Scaffold(
      backgroundColor: StayTokens.paper,
      appBar: AppBar(
        title: Text(state.title, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppPaths.inbox);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading && state.messages.isEmpty) {
                  return const AsyncState.loading(message: 'Loading messages…');
                }
                if (state.error.isNotEmpty && state.messages.isEmpty) {
                  return AsyncState.error(
                    state.error,
                    onRetry: notifier.refresh,
                  );
                }
                if (state.messages.isEmpty) {
                  return const AsyncState.empty(
                    message: 'No messages yet. Say hello!',
                  );
                }
                final offset = state.hasOlder ? 1 : 0;
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(StayTokens.s16),
                  itemCount: state.messages.length + offset,
                  itemBuilder: (context, i) {
                    if (i < offset) {
                      return Center(
                        child: state.isLoadingOlder
                            ? const Padding(
                                padding: EdgeInsets.all(StayTokens.s8),
                                child: CircularProgressIndicator(),
                              )
                            : TextButton(
                                onPressed: notifier.loadOlder,
                                child: const Text('Load earlier messages'),
                              ),
                      );
                    }
                    final message = state.messages[i - offset];
                    return _Bubble(
                      message: message,
                      mine: message.senderId == state.myUserId,
                    );
                  },
                );
              },
            ),
          ),
          if (state.error.isNotEmpty && state.messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: StayTokens.s16),
              child: Text(state.error, style: StayTokens.label),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(StayTokens.s12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Message…',
                        filled: true,
                        fillColor: StayTokens.paperWarm,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            StayTokens.radiusPill,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: StayTokens.s16,
                          vertical: StayTokens.s12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: StayTokens.s8),
                  IconButton.filled(
                    onPressed: state.isSending ? null : _send,
                    icon: state.isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final MessageModel message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: StayTokens.s8),
        padding: const EdgeInsets.symmetric(
          horizontal: StayTokens.s12,
          vertical: StayTokens.s8,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: mine ? StayTokens.ink : StayTokens.paperWarm,
          borderRadius: BorderRadius.circular(StayTokens.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.body,
              style: (mine ? StayTokens.body : StayTokens.body).copyWith(
                color: mine ? Colors.white : StayTokens.ink,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.Hm().format(message.createdAt.toLocal()),
                  style: TextStyle(
                    fontSize: 10,
                    color: mine ? Colors.white70 : StayTokens.inkTertiary,
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.pending ? Icons.schedule : Icons.done,
                    size: 12,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
