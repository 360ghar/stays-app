import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/data/models/message_model.dart';
import '../../../app/ui/widgets/common/empty_state_widget.dart';
import '../../../app/ui/widgets/common/error_widget.dart';
import '../../../app/ui/widgets/common/loading_widget.dart';
import '../controllers/chat_controller.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final ChatController _controller;
  late final TextEditingController _input;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ChatController>();
    _input = TextEditingController();
    _scrollController = ScrollController();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Mark conversation as read when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.markAsRead();
    });
  }

  void _onScroll() {
    // Load more messages when scrolling near the top (older messages)
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 100) {
      _controller.loadMoreMessages();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final conversationId = _controller.conversationId.value;
          return Text(
            conversationId.isEmpty ? 'Chat' : 'Chat · $conversationId',
          );
        }),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(colors),
          ),
          _buildInputArea(colors),
        ],
      ),
    );
  }

  Widget _buildMessageList(ColorScheme colors) {
    return Obx(() {
      // Show loading state
      if (_controller.isLoading.value && _controller.messages.isEmpty) {
        return const LoadingWidget(message: 'Loading messages...');
      }

      // Show error state
      if (_controller.errorMessage.value.isNotEmpty &&
          _controller.messages.isEmpty) {
        return ErrorDisplay(
          message: _controller.errorMessage.value,
          onRetry: _controller.refreshMessages,
        );
      }

      // Show empty state
      if (_controller.messages.isEmpty) {
        return const EmptyStateWidget(
          title: 'No messages yet',
          message: 'Start the conversation by sending a message',
          type: EmptyStateType.messages,
        );
      }

      // Show messages list
      return RefreshIndicator(
        onRefresh: _controller.refreshMessages,
        child: Column(
          children: [
            // Show loading indicator when loading more messages
            if (_controller.isLoadingMore.value)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: SmallLoadingWidget(),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                reverse: true, // Most recent messages at the bottom
                itemCount: _controller.messages.length,
                itemBuilder: (context, index) {
                  // Reverse index since we're using reverse: true
                  final reversedIndex =
                      _controller.messages.length - 1 - index;
                  return _buildMessageBubble(
                    context,
                    _controller.messages[reversedIndex],
                    reversedIndex,
                    colors,
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMessageBubble(
    BuildContext context,
    MessageModel message,
    int index,
    ColorScheme colors,
  ) {
    // Determine if this is a sent message (even index for demo,
    // in production check against current user ID)
    final isSentByMe = index.isEven;

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isSentByMe ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isSentByMe ? 12 : 4),
            bottomRight: Radius.circular(isSentByMe ? 4 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isSentByMe ? colors.onPrimary : colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: (isSentByMe ? colors.onPrimary : colors.onSurface)
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    }
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInputArea(ColorScheme colors) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final isSending = _controller.isSending.value;
              return IconButton.filled(
                icon: isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send),
                onPressed: isSending ? null : () => _sendMessage(_input.text),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _controller.sendMessage(trimmed);
    _input.clear();
  }
}
