import 'package:get/get.dart';

import '../../config/app_config.dart';
import '../controllers/notification/notification_controller.dart';
import '../data/services/analytics_service.dart';
import '../data/services/location_service.dart';
import '../data/services/supabase_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Keep non-async, app-wide services here
    Get.put<LocationService>(LocationService(), permanent: true);
    Get.put<AnalyticsService>(AnalyticsService(enabled: AppConfig.I.enableAnalytics), permanent: true);
    // PushNotificationService is now initialized in SplashController with StorageService dependency
    Get.put<NotificationController>(NotificationController(), permanent: true);
    
    // Initialize Supabase service if needed
    Get.putAsync<SupabaseService>(() async {
      final s = SupabaseService(
        url: AppConfig.I.supabaseUrl,
        anonKey: AppConfig.I.supabaseAnonKey,
      );
      await s.initialize();
      return s;
    }, permanent: true);

    // All critical async services are now handled by SplashController
    // to prevent race conditions
  }
}
