import 'package:get/get.dart';

import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/features/messaging/controllers/chat_controller.dart';
import 'package:stays_app/features/messaging/controllers/hotels_map_controller.dart';

class MessageBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HotelsMapController>()) {
      Get.lazyPut<HotelsMapController>(
        () => HotelsMapController(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<ChatController>()) {
      Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
    }
    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }
  }
}
