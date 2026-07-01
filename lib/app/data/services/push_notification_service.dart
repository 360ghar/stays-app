import 'dart:async';

import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stays_app/config/app_config.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/data/providers/users_provider.dart';
import 'package:stays_app/app/data/services/deep_link_service.dart';
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

      // Foreground messages: show a local notification so the user is aware,
      // and route taps via the same deep-link resolver.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? 'Notification';
        final body = message.notification?.body ?? '';
        AppLogger.info('FCM foreground message: $title');
        unawaited(_showLocalNotification(title, body, message.data));
      });

      // When app is opened from a notification tap (background/terminated).
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.info('Opened from notification ${message.messageId}');
        _routeFromNotificationData(message.data);
      });

      // Cold start from a notification.
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info('App opened from terminated notification');
        _routeFromNotificationData(initialMessage.data);
      }
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

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _localNotificationsInitialized = false;

  Future<void> _ensureLocalNotificationsInitialized() async {
    if (_localNotificationsInitialized) return;
    try {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // The payload carries the FCM data map encoded as a query string.
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _routeFromPayloadString(payload);
          }
        },
      );
      _localNotificationsInitialized = true;
    } catch (e) {
      AppLogger.warning('Local notifications init failed: $e');
    }
  }

  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      await _ensureLocalNotificationsInitialized();
      final payload = _encodeData(data);
      _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    } catch (e) {
      AppLogger.warning('Failed to show local notification: $e');
    }
  }

  /// Routes the user to a specific screen based on FCM `data`.
  /// Supported keys: `type` (booking|message|listing) + `id`, or `deep_link`.
  /// `deep_link` payloads are validated against the same allowlist used by
  /// [DeepLinkService.mapToInternalPath] so an attacker-controlled FCM message
  /// cannot navigate the user to an arbitrary in-app route.
  void _routeFromNotificationData(Map<String, dynamic> data) {
    try {
      final deepLink = data['deep_link']?.toString();
      if (deepLink != null && deepLink.isNotEmpty) {
        // Ponytail: only allow the same listing/chat paths the deep-link
        // service permits. Anything else is dropped and logged.
        final allowlisted = _resolveAllowlistedDeepLink(deepLink);
        if (allowlisted == null) {
          AppLogger.warning(
            'Dropped FCM deep_link outside allowlist: ${_redact(deepLink)}',
          );
          return;
        }
        unawaited(Get.toNamed(allowlisted));
        return;
      }
      final type = data['type']?.toString().toLowerCase();
      final id = data['id']?.toString();
      switch (type) {
        case 'booking':
        case 'inquiry':
          if (id != null) {
            unawaited(Get.toNamed(Routes.inquiries));
          }
          break;
        case 'message':
        case 'chat':
          if (id != null) {
            unawaited(
              Get.toNamed(Routes.chat.replaceAll(':conversationId', id)),
            );
          }
          break;
        case 'listing':
        case 'property':
          if (id != null) {
            unawaited(Get.toNamed(Routes.listingDetail.replaceAll(':id', id)));
          }
          break;
        default:
          break;
      }
    } catch (e) {
      AppLogger.warning('Failed to route from notification data: $e');
    }
  }

  /// Returns the allowlisted internal path for a server-pushed deep link, or
  /// null if the link targets anything outside the allowlist (listing/chat).
  String? _resolveAllowlistedDeepLink(String deepLink) {
    // Accept both bare paths ("/listing/42") and absolute URLs
    // ("https://the360ghar.com/stays/listing/42"). Anything else is rejected.
    final Uri uri;
    try {
      uri = deepLink.startsWith('http')
          ? Uri.parse(deepLink)
          : Uri.parse('https://the360ghar.com$deepLink');
    } catch (_) {
      return null;
    }
    return Get.isRegistered<DeepLinkService>()
        ? Get.find<DeepLinkService>().mapToInternalPath(uri)
        : null;
  }

  static String _redact(String input) {
    if (input.length <= 8) return '****';
    return '${input.substring(0, 4)}****${input.substring(input.length - 4)}';
  }

  void _routeFromPayloadString(String payload) {
    // The payload is the FCM data map encoded with _encodeData.
    final data = _decodeData(payload);
    _routeFromNotificationData(data);
  }

  String _encodeData(Map<String, dynamic> data) {
    return data.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
  }

  Map<String, dynamic> _decodeData(String payload) {
    final result = <String, dynamic>{};
    for (final part in payload.split('&')) {
      final idx = part.indexOf('=');
      if (idx <= 0) continue;
      final key = Uri.decodeComponent(part.substring(0, idx));
      final value = Uri.decodeComponent(part.substring(idx + 1));
      result[key] = value;
    }
    return result;
  }
}
