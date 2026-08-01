import 'dart:async';

import 'package:get/get.dart';

import '../../config/app_config.dart';
import 'package:stays_app/app/controllers/notification/notification_controller.dart';
import '../data/services/deep_link_service.dart';
import '../data/services/analytics_service.dart';
import '../data/services/location_service.dart';
import '../data/services/places_service.dart';
import '../data/services/remember_me_service.dart';
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
import '../data/providers/auth/i_auth_provider.dart';
import '../data/providers/auth_api_provider.dart';
import '../data/providers/properties_provider.dart';
import '../data/providers/supabase_auth_provider.dart';
import '../data/providers/swipes_provider.dart';
import '../data/providers/users_provider.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/properties_repository.dart';
import '../data/repositories/wishlist_repository.dart';
import '../data/services/apple_sign_in_service.dart';
import '../data/services/google_sign_in_service.dart';
import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/features/auth/controllers/form_validation_controller.dart';

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
    unawaited(
      Get.putAsync<CrashReportingService>(() async {
        return CrashReportingService().init();
      }, permanent: true),
    );

    // Initialize async services in dependency order
    // 1) Kick off StorageService initialization asynchronously and keep its future
    final storageFuture = Get.putAsync<StorageService>(() async {
      final service = StorageService();
      await service.initialize();
      return service;
    }, permanent: true);

    // 2) Register TokenService only after StorageService finishes
    if (!Get.isRegistered<TokenService>()) {
      unawaited(
        Get.putAsync<TokenService>(() async {
          await storageFuture; // ensure StorageService is registered and ready
          return TokenService();
        }, permanent: true),
      );
    }

    // Remember-me preference + last-used auth method (single source of truth;
    // never stores tokens — see RememberMeService security contract).
    if (!Get.isRegistered<RememberMeService>()) {
      unawaited(
        Get.putAsync<RememberMeService>(() async {
          return RememberMeService().init();
        }, permanent: true),
      );
    }

    // Initialize Supabase service if needed. Single registration path of
    // record: entry points only kick off `initialize()` in parallel and
    // publish the future on `SupabaseService.supabaseServiceReady`, which
    // we await here to avoid a double init and a missed `_initialized` flag.
    if (!Get.isRegistered<SupabaseService>()) {
      unawaited(
        Get.putAsync<SupabaseService>(() async {
          final s = SupabaseService(
            url: AppConfig.I.supabaseUrl,
            publishableKey: AppConfig.I.supabasePublishableKey,
          );
          if (SupabaseService.supabaseServiceReady != null) {
            await SupabaseService.supabaseServiceReady;
          } else {
            await s.initialize();
          }
          return s;
        }, permanent: true),
      );
    }

    // App-specific services (remove excessive permanent: true)
    Get.put<LocationService>(LocationService());
    Get.put<PlacesService>(PlacesService());
    Get.put<AnalyticsService>(
      AnalyticsService(enabled: AppConfig.I.enableAnalytics),
      permanent: true,
    );

    // Deep link service (receives initial link + live stream)
    Get.put<DeepLinkService>(DeepLinkService(), permanent: true);

    // Property cache service for offline support
    unawaited(
      Get.putAsync<PropertyCacheService>(() async {
        final service = PropertyCacheService();
        await service.init();
        return service;
      }, permanent: true),
    );

    // Image prefetch service for preloading images
    unawaited(
      Get.putAsync<ImagePrefetchService>(() async {
        final service = ImagePrefetchService();
        await service.init();
        return service;
      }, permanent: true),
    );

    // NotificationController is initialized here during app startup
    Get.put<NotificationController>(NotificationController(), permanent: true);

    // ============================================================
    // AUTH GRAPH — canonical single registration (R7 DI consolidation).
    // This binding always runs first (GetMaterialApp.initialBinding), so the
    // cross-feature auth services are registered exactly once here with one
    // consistent lifecycle. Feature bindings must NOT re-register them.
    // ============================================================
    // Native Google/Apple Sign-In wrappers (lazily initialized on first use).
    Get.lazyPut<GoogleSignInService>(() => GoogleSignInService(), fenix: true);
    Get.lazyPut<AppleSignInService>(() => AppleSignInService(), fenix: true);

    // Backend auth state-machine client (identifier-status / last-method).
    Get.lazyPut<AuthApiProvider>(() => AuthApiProvider(), fenix: true);

    // Canonical auth provider: Supabase in all flavors.
    Get.lazyPut<IAuthProvider>(() => SupabaseAuthProvider(), fenix: true);

    // Shared user/profile graph (UsersProvider -> ProfileRepository).
    Get.lazyPut<UsersProvider>(() => UsersProvider(), fenix: true);
    Get.lazyPut<ProfileRepository>(
      () => ProfileRepository(provider: Get.find<UsersProvider>()),
      fenix: true,
    );

    // Shared form-validation controller (auth + profile forms). AuthController
    // resolves it via Get.find (no fallback put — this is the only site).
    Get.lazyPut<FormValidationController>(
      () => FormValidationController(),
      fenix: true,
    );

    // Canonical AuthRepository with the AuthApiProvider wired into it.
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(
        provider: Get.find<IAuthProvider>(),
        authApi: Get.find<AuthApiProvider>(),
      ),
    );

    // Canonical AuthController (single app-wide instance, lazy non-fenix).
    Get.lazyPut<AuthController>(
      () => AuthController(
        authRepository: Get.find<AuthRepository>(),
        tokenService: Get.find<TokenService>(),
      ),
    );

    // ============================================================
    // PROPERTY GRAPH — canonical single registration (R7 DI consolidation).
    // ============================================================
    Get.lazyPut<PropertiesProvider>(() => PropertiesProvider(), fenix: true);
    Get.lazyPut<SwipesProvider>(() => SwipesProvider(), fenix: true);
    Get.lazyPut<PropertiesRepository>(
      () => PropertiesRepository(provider: Get.find<PropertiesProvider>()),
      fenix: true,
    );
    Get.lazyPut<WishlistRepository>(
      () => WishlistRepository(provider: Get.find<SwipesProvider>()),
      fenix: true,
    );

    // Controllers should be lazy-loaded when needed to avoid circular dependencies
    Get.lazyPut<FavoritesController>(() => FavoritesController());
  }
}
