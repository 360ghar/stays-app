import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/messaging/chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});
  @override
  Widget build(BuildContext context) {
    final conversationId = Get.parameters['conversationId'] ?? 'Chat';
    final input = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: Text('Chat · $conversationId')),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.messages.length,
                  itemBuilder: (_, i) => Align(
                    alignment: i.isEven ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: i.isEven ? Colors.black87 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        controller.messages[i],
                        style: TextStyle(color: i.isEven ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                )),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(hintText: 'Type a message'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final text = input.text.trim();
                      if (text.isEmpty) return;
                      controller.messages.add(text);
                      input.clear();
                    },
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
