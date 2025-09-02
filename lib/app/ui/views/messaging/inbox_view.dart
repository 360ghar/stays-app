import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/messaging/conversation_list_controller.dart';

class InboxView extends GetView<ConversationListController> {
  const InboxView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: Obx(() {
        if (controller.conversations.isEmpty) {
          return const Center(child: Text('No conversations yet'));
        }
        return ListView.separated(
          itemCount: controller.conversations.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => ListTile(
            title: Text(controller.conversations[i]),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      }),
    );
  }
}
