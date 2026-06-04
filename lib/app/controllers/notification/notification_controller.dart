import 'package:get/get.dart';

import 'package:stays_app/app/controllers/base/base_controller.dart';

class NotificationController extends BaseController {
  final RxInt unreadCount = 0.obs;

  void markAllRead() => unreadCount.value = 0;
}
