import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stays_app/config/app_config.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/data/providers/users_provider.dart';
import 'storage_service.dart';

/// Background handler must be a top-level function.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Ignore if already initialized
  }
  AppLogger.info('FCM background message: ${message.messageId}');
}

class PushNotificationService extends GetxService {
  PushNotificationService(StorageService _);

  late FirebaseMessaging _messaging;
  bool _firebaseReady = false;

  Future<PushNotificationService> init() async {
    await _initFirebase();
    await _initMessaging();
    AppLogger.info('PushNotificationService initialized');
    return this;
  }

  Future<void> _initFirebase() async {
    try {
      // If options are not configured for this build, this can throw.
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (e) {
      // If Firebase is already initialized or not configured, continue gracefully.
      // Detect already-initialized case via Firebase.apps
      try {
        _firebaseReady = Firebase.apps.isNotEmpty;
      } catch (_) {
        _firebaseReady = false;
      }
      if (!_firebaseReady) {
        AppLogger.warning(
          'Firebase not configured; disabling PushNotificationService. Error: $e',
        );
      }
    }
  }

  Future<void> _initMessaging() async {
    if (!_firebaseReady) {
      // Do not attempt to interact with FirebaseMessaging if Firebase isn't ready.
      return;
    }

    try {
      _messaging = FirebaseMessaging.instance;

      // Register background handler
      try {
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      } catch (e) {
        // Non-fatal; continue without background handling
        AppLogger.warning('Failed to set background handler: $e');
      }

      // Request permissions (iOS/macOS)
      await _messaging.requestPermission();

      // Fetch token for diagnostics
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          // Only log token in dev environment to prevent leaking in production
          if (AppConfig.isDev) {
            AppLogger.info('FCM Token: $token');
          }
          await _registerTokenWithBackend(token);
        }
      } catch (e) {
        AppLogger.warning('Unable to retrieve FCM token: $e');
      }

      // Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? 'Notification';
        AppLogger.info('FCM foreground message: $title');
        // TODO: Optionally show a local notification.
      });

      // When app is opened from a notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.info('Opened from notification ${message.messageId}');
        // TODO: Navigate user to a specific screen based on message data.
      });
    } catch (e) {
      // Guard against any remaining initialization errors.
      AppLogger.warning('Push notifications disabled due to init error: $e');
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      if (!Get.isRegistered<UsersProvider>()) {
        Get.put<UsersProvider>(UsersProvider());
      }
      final provider = Get.find<UsersProvider>();

      String? appVersion;
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = '${info.version}+${info.buildNumber}';
      } catch (_) {
        appVersion = null;
      }

      final locale = Get.locale?.toLanguageTag();
      final platform = kIsWeb
          ? 'web'
          : (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS)
          ? 'ios'
          : 'android';

      await provider.registerDeviceToken(
        token: token,
        platform: platform,
        appVersion: appVersion,
        locale: locale,
      );
      AppLogger.info('Device token registered with backend');
    } catch (e, s) {
      AppLogger.warning('Failed to register device token with backend: $e', s);
    }
  }
}
