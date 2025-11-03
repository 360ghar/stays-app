import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stays_app/app/data/services/push_notification_service.dart';
import 'package:stays_app/app/data/services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class SplashController extends GetxController {
  static const String _rememberMeBox = 'auth_preferences';
  static const String _rememberMeFlagKey = 'remember_me';
  static const String _rememberedAccessTokenKey = 'remembered_access_token';
  static const String _rememberedRefreshTokenKey = 'remembered_refresh_token';

  bool _navigated = false;
  Timer? _watchdog;
  @override
  void onReady() {
    super.onReady();
    // Watchdog: if init/navigate stalls, force fallback after 12s
    _watchdog = Timer(const Duration(seconds: 12), () {
      if (!_navigated) {
        AppLogger.warning(
          'Splash watchdog triggered. Forcing navigation to login.',
        );
        _navigateToNextScreen(forceLogin: true);
      }
    });
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    AppLogger.info('Starting app initialization...');
    try {
      // 1) Storage (critical) with timeout guard
      final StorageService storageService;
      if (Get.isRegistered<StorageService>()) {
        storageService = Get.find<StorageService>();
        AppLogger.info('StorageService already initialized.');
      } else {
        storageService = await Get.putAsync(
          () => StorageService().initialize(),
          permanent: true,
        ).timeout(const Duration(seconds: 5));
        AppLogger.info('StorageService initialized.');
      }

      // 2) Non-critical services: kick off in parallel, do not await
      if (!Get.isRegistered<PushNotificationService>()) {
        Get.putAsync(
              () => PushNotificationService(storageService).init(),
              permanent: true,
            )
            .timeout(const Duration(seconds: 6))
            .then((_) => AppLogger.info('PushNotificationService initialized.'))
            .catchError(
              (e, _) => AppLogger.warning(
                'PushNotificationService init failed/timeout: $e',
              ),
            );
      } else {
        AppLogger.info('PushNotificationService already initialized.');
      }

      AppLogger.info(
        'Core initialization finished. Proceeding to auth check...',
      );
      _navigateToNextScreen();
    } catch (e, stackTrace) {
      AppLogger.error('CRITICAL STARTUP ERROR: $e', e, stackTrace);
      // If a critical service fails (like Storage), show error and fallback
      Get.snackbar(
        'Initialization Failed',
        'Could not start the app. Please check your connection and restart.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      await Future.delayed(const Duration(seconds: 2));
      _navigateToNextScreen(forceLogin: true);
    }
  }

  Future<void> _navigateToNextScreen({bool forceLogin = false}) async {
    // Keep splash visible briefly for UX consistency
    AppLogger.info('Holding splash screen for 5 seconds before navigation.');
    await Future.delayed(const Duration(seconds: 3));

    if (forceLogin) {
      _navigated = true;
      _watchdog?.cancel();
      Get.offAllNamed(Routes.login);
      return;
    }

    try {
      await GetStorage.init(_rememberMeBox);
      final prefs = GetStorage(_rememberMeBox);
      final bool rememberMeEnabled =
          prefs.read<bool>(_rememberMeFlagKey) ?? false;
      final String? rememberedAccessToken =
          prefs.read<String>(_rememberedAccessTokenKey);
      final bool hasStoredToken =
          rememberedAccessToken != null && rememberedAccessToken.isNotEmpty;

      final session = Supabase.instance.client.auth.currentSession;
      final bool hasActiveSession =
          session != null && session.accessToken.isNotEmpty;

      if (!rememberMeEnabled) {
        if (hasActiveSession) {
          AppLogger.info(
            'Remember-me disabled. Clearing existing Supabase session.',
          );
          await Supabase.instance.client.auth.signOut();
        }
        await prefs.remove(_rememberedAccessTokenKey);
        await prefs.remove(_rememberedRefreshTokenKey);
        AppLogger.info('Remember-me disabled. Navigating to login.');
        _navigated = true;
        _watchdog?.cancel();
        Get.offAllNamed(Routes.login);
        return;
      }

      if (rememberMeEnabled && hasStoredToken && hasActiveSession) {
        AppLogger.info('Remember-me token found. Navigating to home.');
        _navigated = true;
        _watchdog?.cancel();
        Get.offAllNamed(Routes.home);
        return;
      }

      if (hasStoredToken && !hasActiveSession) {
        AppLogger.warning(
          'Remember-me token present but Supabase session missing. Clearing cached token.',
        );
        await prefs.remove(_rememberedAccessTokenKey);
        await prefs.remove(_rememberedRefreshTokenKey);
      }

      AppLogger.info(
        'Remember-me enabled but no valid session/token combination. Going to login.',
      );
      _navigated = true;
      _watchdog?.cancel();
      Get.offAllNamed(Routes.login);
    } catch (e) {
      AppLogger.error(
        'Error during navigation check: $e. Navigating to login.',
        e,
      );
      _navigated = true;
      _watchdog?.cancel();
      Get.offAllNamed(Routes.login);
    }
  }
}

