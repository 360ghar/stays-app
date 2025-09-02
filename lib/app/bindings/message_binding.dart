import 'package:get/get.dart';

import '../controllers/messaging/chat_controller.dart';
import '../controllers/messaging/conversation_list_controller.dart';

class MessageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ConversationListController>(() => ConversationListController());
    Get.lazyPut<ChatController>(() => ChatController());
  }
}

