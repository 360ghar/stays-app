import 'package:get/get.dart';

import '../../config/app_config.dart';
import 'package:stays_app/app/controllers/notification/notification_controller.dart';
import '../data/services/analytics_service.dart';
import '../data/services/location_service.dart';
import '../data/services/places_service.dart';
import '../data/services/storage_service.dart';
import '../data/services/supabase_service.dart';
import 'package:stays_app/app/controllers/favorites_controller.dart';
import '../utils/performance/performance_monitor.dart';
import '../utils/services/connectivity_service.dart';
import '../utils/services/error_service.dart';
import '../utils/services/token_service.dart';
import '../utils/services/validation_service.dart';
import '../utils/security/security_service.dart';
import '../data/services/property_cache_service.dart';
import '../data/services/crash_reporting_service.dart';
import '../data/services/image_prefetch_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services that don't depend on others
    if (!Get.isRegistered<ErrorService>()) {
      Get.put<ErrorService>(ErrorService(), permanent: true);
    }
    Get.put<ValidationService>(ValidationService(), permanent: true);
    if (!Get.isRegistered<PerformanceMonitor>()) {
      Get.put<PerformanceMonitor>(PerformanceMonitor(), permanent: true);
    }
    Get.put<SecurityService>(SecurityService(), permanent: true);

    // Connectivity monitoring service (early initialization)
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);

    // Crash reporting service (initialize early for error tracking)
    Get.putAsync<CrashReportingService>(() async {
      return CrashReportingService().init();
    }, permanent: true);

    // Initialize async services in dependency order
    // 1) Kick off StorageService initialization asynchronously and keep its future
    final storageFuture = Get.putAsync<StorageService>(() async {
      final service = StorageService();
      await service.initialize();
      return service;
    }, permanent: true);

    // 2) Register TokenService only after StorageService finishes
    if (!Get.isRegistered<TokenService>()) {
      Get.putAsync<TokenService>(() async {
        await storageFuture; // ensure StorageService is registered and ready
        return TokenService();
      }, permanent: true);
    }

    // Initialize Supabase service if needed
    if (!Get.isRegistered<SupabaseService>()) {
      Get.putAsync<SupabaseService>(() async {
        final s = SupabaseService(
          url: AppConfig.I.supabaseUrl,
          anonKey: AppConfig.I.supabaseAnonKey,
        );
        await s.initialize();
        return s;
      }, permanent: true);
    }

    // App-specific services (remove excessive permanent: true)
    Get.put<LocationService>(LocationService());
    Get.put<PlacesService>(PlacesService());
    Get.put<AnalyticsService>(
      AnalyticsService(enabled: AppConfig.I.enableAnalytics),
    );

    // Property cache service for offline support
    Get.putAsync<PropertyCacheService>(() async {
      final service = PropertyCacheService();
      await service.init();
      return service;
    }, permanent: true);

    // Image prefetch service for preloading images
    Get.putAsync<ImagePrefetchService>(() async {
      final service = ImagePrefetchService();
      await service.init();
      return service;
    }, permanent: true);

    // NotificationController is initialized here during app startup
    Get.put<NotificationController>(NotificationController(), permanent: true);

    // Controllers should be lazy-loaded when needed to avoid circular dependencies
    Get.lazyPut<FavoritesController>(() => FavoritesController());
  }
}
