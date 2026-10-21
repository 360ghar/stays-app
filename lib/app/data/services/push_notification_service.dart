import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stays_app/config/app_config.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/app/data/models/wire_enums.dart';
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

/// Push registration for this device.
///
/// Rules this service keeps once it is started with [init]:
/// - The token is registered with `app_key=stays` at start-up, whenever FCM
///   rotates it ([FirebaseMessaging.onTokenRefresh]) and whenever the user
///   signs in, so the token is bound to the signed-in account.
/// - [unregisterDevice] unbinds it. Call it BEFORE the sign-out: the route
///   needs the session of the caller.
/// - A push opens only the routes the stays app has: a listing and a booking
///   chat (see [DeepLinkService.mapToInternalPath]).
///
/// Nothing constructs and starts this service yet. The backend sends no push
/// to `app_key=stays` (`app_key_for_type` returns ghar or flatmates, and the
/// booking chat sends none), so a token would only add a permission prompt.
/// Call `PushNotificationService.shared.init()` from `ensureV2Bindings` when a
/// stays notification type exists.
class PushNotificationService {
  PushNotificationService(StorageService _, {UsersProvider? usersProvider})
    : _usersProvider = usersProvider ?? UsersProvider();

  /// The one instance the app uses.
  static final PushNotificationService shared = PushNotificationService(
    StorageService(),
  );

  /// Android channel the backend puts on every stays push
  /// (`APP_CHANNEL_IDS["stays"]`). The app creates it, so a push that the
  /// system shows in the background lands in a channel that exists.
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'Notifications',
        importance: Importance.high,
      );

  /// How long a sign-out waits for the unregister call.
  static const Duration unregisterTimeout = Duration(seconds: 5);

  final UsersProvider _usersProvider;
  late FirebaseMessaging _messaging;
  bool _firebaseReady = false;
  bool _messagingReady = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<AuthState>? _authSub;

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

      _messagingReady = true;
      await _ensureLocalNotificationsInitialized();

      // Register the token now, again when FCM rotates it, and again when the
      // user signs in (a token registered before sign-in has no account).
      await _registerCurrentToken();
      _tokenRefreshSub ??= _messaging.onTokenRefresh.listen(
        (token) => unawaited(_registerTokenWithBackend(token)),
      );
      _authSub ??= Supabase.instance.client.auth.onAuthStateChange.listen((
        state,
      ) {
        if (state.event == AuthChangeEvent.signedIn) {
          unawaited(_registerCurrentToken());
        }
      });

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

  Future<void> _registerCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      // Only log token in dev environment to prevent leaking in production
      if (AppConfig.isDev) {
        AppLogger.info('FCM Token: $token');
      }
      await _registerTokenWithBackend(token);
    } catch (e) {
      AppLogger.warning('Unable to retrieve FCM token: $e');
    }
  }

  /// Unbinds this device from the signed-in user
  /// (`DELETE /api/v1/notifications/devices/unregister`). Best effort: it never
  /// throws and gives up after [unregisterTimeout], so a sign-out is never
  /// blocked. Call it before the session ends.
  Future<void> unregisterDevice() async {
    if (!_messagingReady) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _usersProvider
          .unregisterDeviceToken(token)
          .timeout(unregisterTimeout);
      AppLogger.info('Device token unregistered from backend');
    } catch (e) {
      AppLogger.warning('Failed to unregister device token: $e');
    }
  }

  /// Stops listening for token refreshes and sign-ins.
  void dispose() {
    unawaited(_tokenRefreshSub?.cancel());
    unawaited(_authSub?.cancel());
    _tokenRefreshSub = null;
    _authSub = null;
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final provider = _usersProvider;

      String? appVersion;
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = '${info.version}+${info.buildNumber}';
      } catch (_) {
        appVersion = null;
      }

      final locale = PlatformDispatcher.instance.locale.toLanguageTag();
      final platform = kIsWeb
          ? DevicePlatform.web
          : (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS)
          ? DevicePlatform.ios
          : DevicePlatform.android;

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
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          // The payload carries the FCM data map encoded as a query string.
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _routeFromPayloadString(payload);
          }
        },
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
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
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    } catch (e) {
      AppLogger.warning('Failed to show local notification: $e');
    }
  }

  /// FCM route IDs are interpolated into route templates — validate the
  /// format so a malicious payload cannot craft arbitrary paths.
  static bool _isValidRouteId(String? id) {
    if (id == null || id.isEmpty || id.length > 64) return false;
    return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id);
  }

  /// Routes the user to a specific screen based on FCM `data`.
  /// Supported keys: `type` (booking|message|listing) + `id`, or `route`
  /// (older builds of the backend sent `deep_link`).
  /// `deep_link` payloads are validated against the same allowlist used by
  /// [DeepLinkService.mapToInternalPath] so an attacker-controlled FCM message
  /// cannot navigate the user to an arbitrary in-app route.
  void _routeFromNotificationData(Map<String, dynamic> data) {
    try {
      // The backend puts the target in `route`. `deep_link` is the old key.
      final deepLink = (data['route'] ?? data['deep_link'])?.toString();
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
        unawaited(v2RouterInstance().push(allowlisted));
        return;
      }
      final type = data['type']?.toString().toLowerCase();
      final id = data['id']?.toString();
      switch (type) {
        case 'booking':
        case 'inquiry':
          if (id != null) {
            unawaited(v2RouterInstance().push(AppPaths.trips));
          }
          break;
        case 'message':
        case 'chat':
          // The chat of a stay is the thread of its booking: a numeric id.
          if (id != null && int.tryParse(id) != null) {
            final path = '/chat/$id';
            unawaited(v2RouterInstance().push(path));
          } else {
            AppLogger.warning('Dropped FCM route with invalid id: $type/$id');
          }
          break;
        case 'listing':
        case 'property':
          if (_isValidRouteId(id)) {
            final path = '/listing/$id';
            unawaited(v2RouterInstance().push(path));
          } else {
            AppLogger.warning('Dropped FCM route with invalid id: $type/$id');
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
    // Accept bare paths ("/stays/listing/42") and absolute URLs, on https
    // ("https://the360ghar.com/stays/listing/42") or on the app scheme
    // ("stays360://listing/42"). The mapper below allows only a listing and a
    // booking chat, so every other route is dropped.
    final Uri uri;
    try {
      uri = deepLink.contains('://')
          ? Uri.parse(deepLink)
          : Uri.parse('https://the360ghar.com$deepLink');
    } catch (_) {
      return null;
    }
    return DeepLinkService.mapToInternalPath(uri);
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
