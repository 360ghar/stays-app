import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
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
  /// Completes when the async startup chain (StorageService → TokenService,
  /// SupabaseService, caches) finishes registering. Startup ordering contract:
  /// [StorageService] initializes first and publishes [StorageService.ready];
  /// [TokenService] and every other dependent await that future instead of
  /// holding a local putAsync future, so there is exactly one ready signal
  /// per service and no unawaited chain can boot out of order. Supabase init
  /// is kicked off by the entry point and shared via
  /// `SupabaseService.supabaseServiceReady`; this binding only awaits it.
  static final Completer<void> _readyCompleter = Completer<void>();

  /// Single future for the whole async DI chain. Completes (or throws) once
  /// every startup putAsync above has registered.
  static Future<void> get ready => _readyCompleter.future;

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

    // Initialize async services in dependency order.
    // 1) StorageService first; dependents await StorageService.ready (the
    // single ready signal) rather than a local future.
    final storageFuture = Get.putAsync<StorageService>(() async {
      final service = StorageService();
      await service.initialize();
      return service;
    }, permanent: true);

    // 2) TokenService only after StorageService is ready, with the storage
    // handle injected (no Get.find inside the service constructor path).
    final tokenFuture = !Get.isRegistered<TokenService>()
        ? Get.putAsync<TokenService>(() async {
            await StorageService.ready;
            return TokenService(storageService: Get.find<StorageService>());
          }, permanent: true)
        : Future.value(Get.find<TokenService>());

    // Remember-me preference + last-used auth method (single source of truth;
    // never stores tokens — see RememberMeService security contract).
    if (!Get.isRegistered<RememberMeService>()) {
      unawaited(
        Get.putAsync<RememberMeService>(() async {
          return RememberMeService().init();
        }, permanent: true),
      );
    }

    // 3) SupabaseService: entry points kick off `initialize()` in parallel and
    // publish the future on `SupabaseService.supabaseServiceReady`, which we
    // await here to avoid a double init and a missed `_initialized` flag.
    final supabaseFuture = !Get.isRegistered<SupabaseService>()
        ? Get.putAsync<SupabaseService>(() async {
            final s = SupabaseService(
              url: AppConfig.I.auth.supabaseUrl,
              publishableKey: AppConfig.I.auth.supabasePublishableKey,
            );
            if (SupabaseService.supabaseServiceReady != null) {
              await SupabaseService.supabaseServiceReady;
            } else {
              await s.initialize();
            }
            return s;
          }, permanent: true)
        : Future.value(Get.find<SupabaseService>());

    // Single ready future for the auth-critical startup chain. Independent
    // services above (crash reporting, remember-me, caches, prefetch) stay
    // fire-and-forget by design and are intentionally not part of this gate.
    unawaited(
      Future.wait([storageFuture, tokenFuture, supabaseFuture])
          .then((_) {
            if (!_readyCompleter.isCompleted) _readyCompleter.complete();
          })
          .catchError((Object e, StackTrace s) {
            if (!_readyCompleter.isCompleted) {
              _readyCompleter.completeError(e, s);
            }
          }),
    );

    // App-specific services (remove excessive permanent: true)
    Get.put<LocationService>(LocationService());
    Get.put<PlacesService>(PlacesService());
    Get.put<AnalyticsService>(
      AnalyticsService(enabled: AppConfig.I.api.enableAnalytics),
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

    // Canonical auth provider: Supabase in all flavors. Dependencies are
    // injected here — the only site where Get.find fallbacks live.
    Get.lazyPut<IAuthProvider>(
      () => SupabaseAuthProvider(
        client: Supabase.instance.client,
        storage: Get.find<StorageService>(),
        google: Get.find<GoogleSignInService>(),
        apple: Get.find<AppleSignInService>(),
      ),
      fenix: true,
    );

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
    // Get.find fallbacks live here, not in the repository constructor.
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(
        provider: Get.find<IAuthProvider>(),
        authApi: Get.find<AuthApiProvider>(),
        storage: Get.find<StorageService>(),
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
