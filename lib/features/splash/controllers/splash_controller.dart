import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stays_app/app/data/services/app_update_service.dart';
import 'package:stays_app/app/data/services/push_notification_service.dart';
import 'package:stays_app/app/data/services/storage_service.dart';
import 'package:stays_app/app/ui/widgets/dialogs/update_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/utils/services/token_service.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';

class SplashController extends BaseController {
  static const String _rememberMeBox = 'auth_preferences';
  static const String _rememberMeFlagKey = 'remember_me';
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
        'Core initialization finished. Proceeding to update check...',
      );

      // 3) Check for app updates
      final shouldContinue = await _checkForAppUpdate();
      if (!shouldContinue) {
        // Force update required - navigation already handled
        return;
      }

      AppLogger.info('Proceeding to auth check...');
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
      final String? rememberedAccessToken = prefs.read<String>(
        _rememberedAccessTokenKey,
      );
      final String? rememberedRefreshToken = prefs.read<String>(
        _rememberedRefreshTokenKey,
      );
      final bool hasStoredToken =
          rememberedAccessToken != null &&
          rememberedAccessToken.isNotEmpty &&
          rememberedRefreshToken != null &&
          rememberedRefreshToken.isNotEmpty;

      var session = Supabase.instance.client.auth.currentSession;
      bool hasActiveSession = session != null && session.accessToken.isNotEmpty;

      if (rememberMeEnabled && hasStoredToken && !hasActiveSession) {
        session = await _restoreRememberedSession(
          prefs: prefs,
          refreshToken: rememberedRefreshToken,
        );
        hasActiveSession = session != null && session.accessToken.isNotEmpty;
      }

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
        unawaited(Get.offAllNamed(Routes.login));
        return;
      }

      if (rememberMeEnabled && hasStoredToken && hasActiveSession) {
        AppLogger.info('Remember-me token found. Navigating to home.');
        _navigated = true;
        _watchdog?.cancel();
        unawaited(Get.offAllNamed(Routes.home));
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

  Future<Session?> _restoreRememberedSession({
    required GetStorage prefs,
    required String refreshToken,
  }) async {
    try {
      AppLogger.info(
        'Attempting to restore Supabase session from stored refresh token.',
      );
      final response = await Supabase.instance.client.auth.setSession(
        refreshToken,
      );
      final restoredSession = response.session;
      if (restoredSession == null) {
        AppLogger.warning(
          'Supabase returned no session when restoring remember-me tokens.',
        );
        return null;
      }
      // Keep TokenService in sync so downstream auth checks see tokens immediately
      try {
        final tokenService = Get.find<TokenService>();
        await tokenService.storeTokens(
          accessToken: restoredSession.accessToken,
          refreshToken: restoredSession.refreshToken,
        );
      } catch (_) {
        if (Get.isRegistered<StorageService>()) {
          final storage = Get.find<StorageService>();
          await storage.saveTokens(
            accessToken: restoredSession.accessToken,
            refreshToken: restoredSession.refreshToken,
          );
        }
      }
      await prefs.write(_rememberedAccessTokenKey, restoredSession.accessToken);
      final newRefreshToken = restoredSession.refreshToken;
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await prefs.write(_rememberedRefreshTokenKey, newRefreshToken);
      }
      return restoredSession;
    } catch (e) {
      AppLogger.warning(
        'Failed to restore Supabase session from remember-me tokens: $e',
      );
      return null;
    }
  }

  /// Check for app updates.
  ///
  /// Returns `true` if the app should continue to the next screen,
  /// `false` if a force update is required (navigation already handled).
  Future<bool> _checkForAppUpdate() async {
    try {
      // Initialize AppUpdateService if not already registered
      if (!Get.isRegistered<AppUpdateService>()) {
        await Get.putAsync<AppUpdateService>(
          () => AppUpdateService().init(),
          permanent: true,
        ).timeout(const Duration(seconds: 10));
        AppLogger.info('AppUpdateService initialized.');
      }

      final updateService = Get.find<AppUpdateService>();
      await updateService.checkForUpdate();

      // Check if force update is required
      if (updateService.isForceUpdate.value) {
        AppLogger.info('Force update required. Navigating to update screen.');
        _navigated = true;
        _watchdog?.cancel();
        unawaited(Get.offAllNamed(Routes.forceUpdate));
        return false;
      }

      // Check if optional update is available and should be shown
      if (updateService.isUpdateAvailable.value &&
          updateService.shouldShowUpdatePrompt()) {
        AppLogger.info('Optional update available. Will show dialog after navigation.');
        // Schedule dialog to show after navigation completes
        _scheduleOptionalUpdateDialog(updateService);
      }

      return true;
    } catch (e) {
      AppLogger.warning('Update check failed: $e. Continuing with app.');
      return true;
    }
  }

  /// Schedule the optional update dialog to show after navigation completes.
  void _scheduleOptionalUpdateDialog(AppUpdateService updateService) {
    // Use a post-frame callback to show the dialog after the next screen renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait a bit for the navigation to settle
      Future.delayed(const Duration(milliseconds: 500), () {
        _showOptionalUpdateDialog(updateService);
      });
    });
  }

  /// Show the optional update dialog.
  void _showOptionalUpdateDialog(AppUpdateService updateService) {
    final context = Get.context;
    if (context == null) {
      AppLogger.warning('No context available for update dialog.');
      return;
    }

    showUpdateDialog(
      context,
      currentVersion: updateService.currentVersion,
      newVersion: updateService.storeVersion.value,
      releaseNotes: updateService.releaseNotes.value.isNotEmpty
          ? updateService.releaseNotes.value
          : null,
      onUpdate: () => updateService.openStore(),
    ).then((result) {
      if (result == UpdateDialogResult.later) {
        updateService.recordDismissal();
      }
    });
  }
}
