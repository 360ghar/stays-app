import 'package:get/get.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'storage_service.dart';

class PushNotificationService extends GetxService {
  PushNotificationService(StorageService _);

  Future<PushNotificationService> init() async {
    AppLogger.info('PushNotificationService initialized');
    return this;
  }
}
