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
    // Initialize sync services first
    Get.put<LocationService>(LocationService(), permanent: true);
    Get.put<AnalyticsService>(AnalyticsService(enabled: AppConfig.I.enableAnalytics), permanent: true);
    Get.put<PushNotificationService>(PushNotificationService(), permanent: true);
    Get.put<NotificationController>(NotificationController(), permanent: true);
    
    // Initialize async services
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

    // Don't initialize PhoneAuthController here - let specific bindings handle it
    // This prevents issues with async dependencies not being ready

    // Don't initialize AuthController here - let AuthBinding handle it
    // This prevents timing issues with async services
  }
}
