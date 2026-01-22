import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stays_app/app/data/services/push_notification_service.dart';
import 'package:stays_app/app/data/services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/utils/services/token_service.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';

class SplashController extends BaseController {
  static const String _rememberMeBox = 'auth_preferences';
  static const String _rememberMeFlagKey = 'remember_me';
  // Legacy keys from older builds (plaintext tokens). Kept for one-time cleanup.
  static const String _rememberedAccessTokenKey = 'remembered_access_token';
  static const String _rememberedRefreshTokenKey = 'remembered_refresh_token';

  bool _navigated = false;
  Timer? _watchdog;

  @override
  void onClose() {
    _watchdog?.cancel();
    super.onClose();
  }

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
        unawaited(
          Get.putAsync(
                () => PushNotificationService(storageService).init(),
                permanent: true,
              )
              .timeout(const Duration(seconds: 6))
              .then(
                (_) => AppLogger.info('PushNotificationService initialized.'),
              )
              .catchError(
                (e, _) => AppLogger.warning(
                  'PushNotificationService init failed/timeout: $e',
                ),
              ),
        );
      } else {
        AppLogger.info('PushNotificationService already initialized.');
      }

      AppLogger.info(
        'Core initialization finished. Proceeding to auth check...',
      );
      unawaited(_navigateToNextScreen());
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
      unawaited(_navigateToNextScreen(forceLogin: true));
    }
  }

  Future<void> _navigateToNextScreen({bool forceLogin = false}) async {
    // Keep splash visible briefly for UX consistency
    await Future.delayed(const Duration(milliseconds: 800));

    if (forceLogin) {
      _navigated = true;
      _watchdog?.cancel();
      unawaited(Get.offAllNamed(Routes.login));
      return;
    }

    try {
      await GetStorage.init(_rememberMeBox);
      final prefs = GetStorage(_rememberMeBox);
      final bool rememberMeEnabled =
          prefs.read<bool>(_rememberMeFlagKey) ?? false;

      final storage = Get.find<StorageService>();
      final tokenService = Get.isRegistered<TokenService>()
          ? Get.find<TokenService>()
          : null;
      if (tokenService != null) {
        await tokenService.ready;
      }

      final legacyAccess = prefs.read<String>(_rememberedAccessTokenKey);
      final legacyRefresh = prefs.read<String>(_rememberedRefreshTokenKey);

      var session = Supabase.instance.client.auth.currentSession;
      bool hasActiveSession = session != null && session.accessToken.isNotEmpty;

      if (!rememberMeEnabled) {
        AppLogger.info('Remember-me disabled. Clearing session/tokens.');
        await _clearLegacyRememberedSession(prefs);
        await _signOutAndClear(storage, tokenService);
        _navigated = true;
        _watchdog?.cancel();
        unawaited(Get.offAllNamed(Routes.login));
        return;
      }

      // Try to restore Supabase session if none exists
      if (!hasActiveSession) {
        if (legacyRefresh != null && legacyRefresh.isNotEmpty) {
          session = await _restoreSessionFromRefreshToken(legacyRefresh);
          hasActiveSession =
              session != null && session.accessToken.isNotEmpty;
        }
        if (!hasActiveSession) {
          final secureRefresh = await storage.getRefreshToken();
          if (secureRefresh != null && secureRefresh.isNotEmpty) {
            session = await _restoreSessionFromRefreshToken(secureRefresh);
            hasActiveSession =
                session != null && session.accessToken.isNotEmpty;
          }
        }
      }

      if (hasActiveSession) {
        await _syncTokenServiceFromSession(session!, storage, tokenService);
        await _clearLegacyRememberedSession(prefs);
        AppLogger.info('Active session detected. Navigating to home.');
        _navigated = true;
        _watchdog?.cancel();
        unawaited(Get.offAllNamed(Routes.home));
        return;
      }

      // Fallback: if token service already has valid tokens, allow navigation.
      if (tokenService?.hasValidToken == true) {
        await _clearLegacyRememberedSession(prefs);
        AppLogger.info('Valid tokens detected. Navigating to home.');
        _navigated = true;
        _watchdog?.cancel();
        unawaited(Get.offAllNamed(Routes.home));
        return;
      }

      await _clearLegacyRememberedSession(prefs);
      AppLogger.info(
        'Remember-me enabled but no valid session/tokens. Going to login.',
      );
      _navigated = true;
      _watchdog?.cancel();
      unawaited(Get.offAllNamed(Routes.login));
    } catch (e) {
      AppLogger.error(
        'Error during navigation check: $e. Navigating to login.',
        e,
      );
      _navigated = true;
      _watchdog?.cancel();
      unawaited(Get.offAllNamed(Routes.login));
    }
  }

  Future<Session?> _restoreSessionFromRefreshToken(String refreshToken) async {
    try {
      AppLogger.info(
        'Attempting to restore Supabase session from refresh token.',
      );
      final response = await Supabase.instance.client.auth.setSession(
        refreshToken,
      );
      final restoredSession = response.session;
      if (restoredSession == null) {
        AppLogger.warning(
          'Supabase returned no session when restoring refresh token.',
        );
        return null;
      }
      return restoredSession;
    } catch (e) {
      AppLogger.warning(
        'Failed to restore Supabase session from refresh token: $e',
      );
      return null;
    }
  }

  Future<void> _syncTokenServiceFromSession(
    Session session,
    StorageService storageService,
    TokenService? tokenService,
  ) async {
    try {
      if (tokenService != null) {
        await tokenService.storeTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
        return;
      }
    } catch (_) {}
    await storageService.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
  }

  Future<void> _clearLegacyRememberedSession(GetStorage prefs) async {
    await prefs.remove(_rememberedAccessTokenKey);
    await prefs.remove(_rememberedRefreshTokenKey);
  }

  Future<void> _signOutAndClear(
    StorageService storageService,
    TokenService? tokenService,
  ) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    try {
      await tokenService?.clearTokens();
    } catch (_) {}
    try {
      await storageService.clearTokens();
      await storageService.clearUserData();
    } catch (_) {}
  }
}
