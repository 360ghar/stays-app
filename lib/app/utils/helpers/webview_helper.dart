import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'
    as webview_android;
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../logger/app_logger.dart';

class WebViewHelper {
  WebViewHelper._();

  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) {
      return;
    }
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        WebViewPlatform.instance ??= webview_android.AndroidWebViewPlatform();
        // Debug bridge must never ship in release builds.
        if (kDebugMode) {
          unawaited(
            webview_android.AndroidWebViewController.enableDebugging(true),
          );
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        WebViewPlatform.instance ??= WebKitWebViewPlatform();
      }
    }
    _initialized = true;
  }

  static bool isKuulaUrl(String url) {
    return url.toLowerCase().contains('kuula.co');
  }

  /// Hosts the tour webview may navigate to. Anything else is blocked.
  static const Set<String> _allowedTourHosts = {'kuula.co', 'www.kuula.co'};

  /// Default navigation policy for tour webviews: only `https` URLs on the
  /// Kuula embed hosts may load. All other schemes/hosts are blocked so a
  /// backend-supplied `virtualTourUrl` cannot drive the user to arbitrary
  /// content inside the app's webview.
  static NavigationDecision defaultNavigationPolicy(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null || uri.scheme != 'https') {
      AppLogger.warning(
        'Blocked webview navigation (non-https): ${request.url}',
      );
      return NavigationDecision.prevent;
    }
    final host = uri.host.toLowerCase();
    final allowed =
        _allowedTourHosts.contains(host) || host.endsWith('.kuula.co');
    if (!allowed) {
      AppLogger.warning('Blocked webview navigation to: $host');
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  static String _normalizeKuulaUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return url;
    }
    if (uri.scheme != 'https') {
      // load() rejects non-https up front; keep the raw value for the log.
      return url;
    }
    final host = uri.host.toLowerCase();
    final isKuulaHost = host == 'kuula.co' || host.endsWith('.kuula.co');
    if (!isKuulaHost) {
      return url;
    }
    final updatedQuery = Map<String, String>.from(uri.queryParameters)
      ..['vr'] = '0'
      ..['gyro'] = '0'
      ..['sd'] = '1';
    return uri.replace(queryParameters: updatedQuery).toString();
  }

  /// Minimal HTML-escaping for values interpolated into [buildKuulaHtml].
  static String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String buildKuulaHtml(String url) {
    final sanitized = _normalizeKuulaUrl(url.trim());
    // Defense in depth: the URL has already passed scheme/host validation,
    // but escape it anyway before interpolating into the HTML.
    final escaped = _escapeHtml(sanitized);
    return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
      html, body {
        margin: 0;
        padding: 0;
        background-color: #000000;
        overflow: hidden;
        height: 100%;
        width: 100%;
      }
      iframe {
        width: 100vw;
        height: 100vh;
        border: none;
      }
    </style>
  </head>
  <body>
    <iframe
      class="ku-embed"
      frameborder="0"
      allow="xr-spatial-tracking"
      sandbox="allow-scripts allow-same-origin allow-forms allow-popups"
      allowfullscreen
      scrolling="no"
      src="$escaped"
    ></iframe>
  </body>
</html>
''';
  }

  static PlatformWebViewControllerCreationParams _createParams() {
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return webview_android.AndroidWebViewControllerCreationParams();
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      }
    }
    return const PlatformWebViewControllerCreationParams();
  }

  static WebViewController createController({
    void Function(String url)? onPageStarted,
    void Function(String url)? onPageFinished,
    void Function(WebResourceError error)? onWebResourceError,
    void Function(int progress)? onProgress,
    NavigationDecision Function(NavigationRequest request)? onNavigationRequest,
  }) {
    final controller = WebViewController.fromPlatformCreationParams(
      _createParams(),
    );
    unawaited(controller.setJavaScriptMode(JavaScriptMode.unrestricted));
    unawaited(controller.setBackgroundColor(Colors.black));
    unawaited(
      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: onPageStarted,
          onPageFinished: onPageFinished,
          onWebResourceError: onWebResourceError,
          onProgress: onProgress,
          // Default to the safe Kuula-only policy when the caller does not
          // supply a custom one.
          onNavigationRequest: onNavigationRequest ?? defaultNavigationPolicy,
        ),
      ),
    );

    if (controller.platform is webview_android.AndroidWebViewController) {
      final androidController =
          controller.platform as webview_android.AndroidWebViewController;
      unawaited(androidController.setMediaPlaybackRequiresUserGesture(false));
    }

    return controller;
  }

  static Future<void> load(String url, WebViewController controller) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    // Only https URLs may load inside the app webview.
    if (uri == null || uri.scheme != 'https') {
      AppLogger.warning('Blocked webview load (non-https): $url');
      return;
    }
    if (isKuulaUrl(url)) {
      await controller.loadHtmlString(buildKuulaHtml(url));
    } else {
      await controller.loadRequest(uri);
    }
  }

  static Future<void> injectResponsiveStyles(
    WebViewController controller,
  ) async {
    const script = '''
      document.body.style.margin = '0';
      document.body.style.padding = '0';
      var iframes = document.getElementsByTagName('iframe');
      for (var i = 0; i < iframes.length; i++) {
        iframes[i].style.width = '100%';
        iframes[i].style.height = '100vh';
        iframes[i].style.border = 'none';
      }
    ''';
    try {
      await controller.runJavaScript(script);
    } catch (_) {
      // Ignore failures (for example, cross-origin restrictions).
    }
  }

  static Widget buildErrorWidget({
    double? width,
    double? height,
    VoidCallback? onRetry,
    String? url,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.public_off, size: 32),
            const SizedBox(height: 8),
            const Text('360-degree tour unavailable'),
            const SizedBox(height: 4),
            const Text('Virtual tour could not be loaded'),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
            if (kIsWeb && url != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final uri = Uri.tryParse(url);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Open in new tab'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
