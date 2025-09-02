import 'package:get/get.dart';

class NotificationController extends GetxController {
  final RxInt unreadCount = 0.obs;

  void markAllRead() => unreadCount.value = 0;
}

