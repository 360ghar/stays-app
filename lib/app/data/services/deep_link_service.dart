import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class DeepLinkService extends GetxService {
  StreamSubscription? _sub;
  final AppLinks _appLinks = AppLinks();
  final Rxn<String> pendingDeepLink = Rxn<String>();

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
    final segments = uri.pathSegments;
    if (segments.isEmpty) return null;

    final firstSegment = segments[0];

    if (firstSegment == 'stays' && segments.length >= 2) {
      return _mapStaysPrefix(segments.sublist(1));
    }

    if (firstSegment == 'listing' && segments.length >= 2) {
      return _buildListingPath(segments[1]);
    }

    if (firstSegment == 'chat' && segments.length >= 2) {
      return _buildChatPath(segments[1]);
    }

    return null;
  }

  String? _mapStaysPrefix(List<String> segments) {
    if (segments.isEmpty) return null;

    final subPath = segments[0];

    if (subPath == 'listing' && segments.length >= 2) {
      return _buildListingPath(segments[1]);
    }

    if (subPath == 'chat' && segments.length >= 2) {
      return _buildChatPath(segments[1]);
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