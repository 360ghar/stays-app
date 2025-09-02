import 'package:get/get.dart';

import '../../config/app_config.dart';
import '../controllers/notification/notification_controller.dart';
import '../data/services/analytics_service.dart';
import '../data/services/location_service.dart';
import '../data/services/push_notification_service.dart';
import '../data/services/storage_service.dart';
import '../data/services/supabase_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.putAsync<StorageService>(() async {
      final s = StorageService();
      await s.initialize();
      return s;
    }, permanent: true);
    Get.putAsync<SupabaseService>(() async {
      final s = SupabaseService(
        url: AppConfig.I.supabaseUrl,
        anonKey: AppConfig.I.supabaseAnonKey,
      );
      await s.initialize();
      return s;
    }, permanent: true);
    Get.put<LocationService>(LocationService(), permanent: true);
    Get.put<AnalyticsService>(AnalyticsService(enabled: AppConfig.I.enableAnalytics), permanent: true);
    Get.put<PushNotificationService>(PushNotificationService(), permanent: true);

    Get.put<NotificationController>(NotificationController(), permanent: true);
  }
}
