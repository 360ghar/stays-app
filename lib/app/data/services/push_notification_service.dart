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

  Future<PushNotificationService> init() async {
    await _initFirebase();
    await _initMessaging();
    AppLogger.info('PushNotificationService initialized');
    return this;
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // If Firebase is already initialized, ignore the error.
    }
  }

  Future<void> _initMessaging() async {
    _messaging = FirebaseMessaging.instance;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
  }
}
