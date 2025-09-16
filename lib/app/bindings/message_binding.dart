import 'package:get/get.dart';

import '../controllers/messaging/chat_controller.dart';
import '../controllers/messaging/hotels_map_controller.dart';
import '../controllers/filter_controller.dart';

class MessageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HotelsMapController>(() => HotelsMapController());
    Get.lazyPut<ChatController>(() => ChatController());
    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }
  }
}
