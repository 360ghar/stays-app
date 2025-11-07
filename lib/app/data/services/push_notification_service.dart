import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
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
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      // Fetch token for diagnostics
      try {
        final token = await _messaging.getToken();
        if (token != null) AppLogger.info('FCM Token: $token');
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
}
