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
    // the uriLinkStream depending on platform/version. Dedupe so a single
    // launch link is never navigated twice.
    final uriString = uri.toString();
    if (uriString == _lastHandledUri) return;
    _lastHandledUri = uriString;

    AppLogger.info('🔗 Received Deep Link: $uri');

    final internalPath = _mapToInternalPath(uri);

    if (internalPath != null) {
      AppLogger.info('🔗 Mapped to internal path: $internalPath');
      _navigateToPath(internalPath);
    } else {
      AppLogger.warning('🔗 Could not parse deep link: $uri');
    }
  }

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

  void _navigateToPath(String path) {
    pendingDeepLink.value = path;
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        Get.toNamed(path);
      } catch (e) {
        AppLogger.error('🔗 Failed to navigate to deep link path: $path', e);
        // If navigation fails (e.g. auth middleware redirects to login),
        // the pendingDeepLink is preserved for post-login replay.
      }
    });
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

  static String chatUrl(String chatId) =>
      '$_baseUrl/stays/chat/$chatId';
}