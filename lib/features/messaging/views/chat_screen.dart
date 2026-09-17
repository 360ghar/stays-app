import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stays_app/app/data/models/message_model.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/core/ui/async_state.dart';
import 'package:stays_app/features/messaging/providers/chat_providers.dart';

/// V2 chat. Realtime bubbles, optimistic send, read receipts.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.conversationId, super.key});
  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  String get _me {
    try {
      return Supabase.instance.client.auth.currentUser?.id ?? '';
    } catch (_) {
      return '';
    }
  }

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
    await ref
        .read(chatProvider(widget.conversationId).notifier)
        .send(widget.conversationId, text);
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider(widget.conversationId));
    final notifier = ref.read(chatProvider(widget.conversationId).notifier);
    ref.listen(chatProvider(widget.conversationId), (_, next) {
      if (next.messages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      }
    });
    return Scaffold(
      backgroundColor: StayTokens.paper,
      appBar: AppBar(
        title: const Text('Chat'),
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
                    onRetry: () => notifier.refresh(widget.conversationId),
                  );
                }
                if (state.messages.isEmpty) {
                  return const AsyncState.empty(
                    message: 'No messages yet. Say hello!',
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(StayTokens.s16),
                  itemCount: state.messages.length,
                  itemBuilder: (context, i) => _Bubble(
                    message: state.messages[i],
                    mine: state.messages[i].senderId == _me,
                  ),
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
              message.content,
              style: (mine ? StayTokens.body : StayTokens.body).copyWith(
                color: mine ? Colors.white : StayTokens.ink,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.Hm().format(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: mine ? Colors.white70 : StayTokens.inkTertiary,
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
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
