import 'package:get/get.dart';

import '../controllers/messaging/chat_controller.dart';
import '../controllers/messaging/hotels_map_controller.dart';

class MessageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HotelsMapController>(() => HotelsMapController());
    Get.lazyPut<ChatController>(() => ChatController());
  }
}

