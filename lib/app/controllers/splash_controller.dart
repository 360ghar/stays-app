import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/data/services/api_service.dart';
import 'package:stays_app/app/data/services/properties_service.dart';
import 'package:stays_app/app/data/services/push_notification_service.dart';
import 'package:stays_app/app/data/services/storage_service.dart';
import 'package:stays_app/app/data/services/wishlist_service.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class SplashController extends GetxController {
  bool _navigated = false;
  Timer? _watchdog;
  @override
  void onReady() {
    super.onReady();
    // Watchdog: if init/navigate stalls, force fallback after 12s
    _watchdog = Timer(const Duration(seconds: 12), () {
      if (!_navigated) {
        AppLogger.warning('Splash watchdog triggered. Forcing navigation to login.');
        _navigateToNextScreen(forceLogin: true);
      }
    });
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    AppLogger.info('Starting app initialization...');
    try {
      // 1) Storage (critical) with timeout guard
      final storageService = await Get
          .putAsync(() => StorageService().initialize(), permanent: true)
          .timeout(const Duration(seconds: 5));
      AppLogger.info('StorageService initialized.');

      // 2) ApiService (critical) — register eagerly; let onInit run once
      // Avoid calling a custom init that re-calls onInit (which caused LateInitializationError)
      Get.put<ApiService>(ApiService(), permanent: true);
      // Allow a brief tick for onInit to schedule
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final apiService = ApiService.instance;
      AppLogger.info('ApiService initialized.');

      // 3) Non-critical services: kick off in parallel, do not await
      Get
          .putAsync(() => PropertiesService(apiService).init(), permanent: true)
          .timeout(const Duration(seconds: 6))
          .then((_) => AppLogger.info('PropertiesService initialized.'))
          .catchError((e, _) => AppLogger.warning('PropertiesService init failed/timeout: $e'));

      Get
          .putAsync(() => WishlistService(apiService).init(), permanent: true)
          .timeout(const Duration(seconds: 6))
          .then((_) => AppLogger.info('WishlistService initialized.'))
          .catchError((e, _) => AppLogger.warning('WishlistService init failed/timeout: $e'));

      Get
          .putAsync(() => PushNotificationService(storageService).init(), permanent: true)
          .timeout(const Duration(seconds: 6))
          .then((_) => AppLogger.info('PushNotificationService initialized.'))
          .catchError((e, _) => AppLogger.warning('PushNotificationService init failed/timeout: $e'));

      AppLogger.info('Core initialization finished. Proceeding to auth check...');
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
    await Future.delayed(const Duration(milliseconds: 800));

    if (forceLogin) {
      _navigated = true;
      _watchdog?.cancel();
      Get.offAllNamed(Routes.login);
      return;
    }

    try {
      final storage = Get.find<StorageService>();
      final token = await storage.getAccessToken();

      if (token != null) {
        AppLogger.info('Token found. Navigating to home.');
        _navigated = true;
        _watchdog?.cancel();
        Get.offAllNamed(Routes.home);
      } else {
        AppLogger.info('No token found. Navigating to login.');
        _navigated = true;
        _watchdog?.cancel();
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      AppLogger.error('Error during navigation check: $e. Navigating to login.', e);
      _navigated = true;
      _watchdog?.cancel();
      Get.offAllNamed(Routes.login);
    }
  }
}
