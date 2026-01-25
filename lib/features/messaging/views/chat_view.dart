import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/features/messaging/controllers/chat_controller.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final ChatController _controller;
  late final TextEditingController _input;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ChatController>();
    _input = TextEditingController();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
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
            child: Obx(
              () => ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _controller.messages.length,
                itemBuilder: (_, i) => Align(
                  alignment: i.isEven
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: i.isEven
                          ? colors.primary
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _controller.messages[i],
                      style: TextStyle(
                        color: i.isEven ? colors.onPrimary : colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final text = _input.text.trim();
                      if (text.isEmpty) return;
                      _controller.messages.add(text);
                      _input.clear();
                    },
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
