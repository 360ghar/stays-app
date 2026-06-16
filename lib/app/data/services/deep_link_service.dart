import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class DeepLinkService extends GetxService {
  StreamSubscription<Uri?>? _sub;
  final AppLinks _appLinks = AppLinks();
  final Rxn<String> pendingDeepLink = Rxn<String>();
  String? _lastHandledUri;
  DateTime? _lastHandledAt;

  /// Window within which an identical URI is treated as a duplicate. app_links
  /// can deliver the cold-start link via both getInitialLink() and
  /// uriLinkStream within milliseconds; outside this window the same link may
  /// be legitimately re-opened later in the session.
  static const Duration _dedupeWindow = Duration(seconds: 2);

  static const String _baseUrl = 'https://the360ghar.com';

  @override
  void onInit() {
    super.onInit();
    _initDeepLinks();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> _initDeepLinks() async {
    if (kIsWeb) return;

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleDeepLink(initialUri);
        });
      }
    } on PlatformException catch (e) {
      AppLogger.warning('Failed to get initial deep link: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      },
      onError: (Object err) {
        AppLogger.error('Deep link stream error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    // app_links may surface the cold-start link via both getInitialLink() and
    // the uriLinkStream within milliseconds. Dedupe only within a short window
    // so a user can still re-open the same link later in the session.
    final uriString = uri.toString();
    final now = DateTime.now();
    if (uriString == _lastHandledUri &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < _dedupeWindow) {
      return;
    }
    _lastHandledUri = uriString;
    _lastHandledAt = now;

    AppLogger.info('🔗 Received Deep Link: ${_redact(uri)}');

    final internalPath = _mapToInternalPath(uri);

    if (internalPath != null) {
      AppLogger.info('🔗 Mapped to internal path: $internalPath');
      unawaited(_navigateToPath(internalPath));
    } else {
      AppLogger.warning('🔗 Could not parse deep link: ${_redact(uri)}');
    }
  }

  /// Strips query and fragment before logging — deep-link params may carry
  /// tokens or other sensitive data that should never be written to the logs.
  static Uri _redact(Uri uri) => uri.replace(query: '', fragment: '');

  String? _mapToInternalPath(Uri uri) {
    var segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    // Links may be namespaced under a leading "stays" prefix
    // (e.g. /stays/listing/42) or come through bare (e.g. /listing/42).
    if (segments.first == 'stays') {
      segments = segments.sublist(1);
    }
    if (segments.length < 2) return null;

    final entity = segments[0];
    final id = segments[1];
    switch (entity) {
      case 'listing':
        return _buildListingPath(id);
      case 'chat':
        return _buildChatPath(id);
    }
    return null;
  }

  String _buildListingPath(String listingId) =>
      Routes.listingDetail.replaceAll(':id', listingId);

  String _buildChatPath(String conversationId) =>
      Routes.chat.replaceAll(':conversationId', conversationId);

  Future<void> _navigateToPath(String path) async {
    pendingDeepLink.value = path;
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      await Get.toNamed(path);
      // If we actually landed on the target (an AuthMiddleware did not bounce
      // us to login), the pending link is consumed — clear it so it can't be
      // replayed later. On an auth redirect it is intentionally left set.
      if (Get.currentRoute == path) {
        pendingDeepLink.value = null;
      }
    } catch (e) {
      AppLogger.error('🔗 Failed to navigate to deep link path: $path', e);
    }
  }

  String? consumePendingDeepLink() {
    final path = pendingDeepLink.value;
    if (path != null) {
      pendingDeepLink.value = null;
      AppLogger.info('🔗 Consuming pending deep link: $path');
    }
    return path;
  }

  void navigateToPendingDeepLink() {
    final path = consumePendingDeepLink();
    if (path != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.toNamed(path);
      });
    }
  }

  static String listingUrl(String listingId) =>
      '$_baseUrl/stays/listing/$listingId';

  static String chatUrl(String chatId) => '$_baseUrl/stays/chat/$chatId';
}
