import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/app/data/models/message_model.dart';
import 'package:stays_app/features/messaging/controllers/chat_controller.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final ChatController _controller;
  late final TextEditingController _input;
  late final ScrollController _scroll;
  final RxBool _showSend = false.obs;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ChatController>();
    _input = TextEditingController();
    _scroll = ScrollController();
    _input.addListener(() {
      _showSend.value = _input.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onSend() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    _showSend.value = false;
    await _controller.send(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final conversationId = Get.parameters['conversationId'] ?? 'Chat';
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Chat · $conversationId')),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value && _controller.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_controller.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 56,
                        color: colors.outline,
                      ),
                      const SizedBox(height: 12),
                      const Text('Say hello to start the conversation'),
                    ],
                  ),
                );
              }
              final count = _controller.messages.length;
              final grew = count > _lastMessageCount;
              _lastMessageCount = count;
              if (grew) {
                _scrollToBottom();
              }
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: _controller.messages.length,
                itemBuilder: (_, i) => _MessageBubble(
                  message: _controller.messages[i],
                  currentUserId: _controller.currentUserId,
                ),
              );
            }),
          ),
          _typingIndicator(colors),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => IconButton.filled(
                      onPressed:
                          (_showSend.value || _controller.isSending.value)
                          ? _onSend
                          : null,
                      icon: _controller.isSending.value
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingIndicator(ColorScheme colors) {
    return Obx(() {
      final typing = _controller.otherUserTyping.value;
      if (typing.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '$typing is typing…',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
        ),
      );
    });
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.currentUserId});

  final MessageModel message;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isMine = message.senderId == currentUserId;
    final time = TimeOfDay.fromDateTime(message.createdAt).format(context);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isMine ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMine ? 12 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMine ? colors.onPrimary : colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine
                        ? colors.onPrimary.withValues(alpha: 0.8)
                        : colors.onSurfaceVariant,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.readAt == null ? Icons.done : Icons.done_all,
                    size: 14,
                    color: colors.onPrimary.withValues(alpha: 0.8),
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
