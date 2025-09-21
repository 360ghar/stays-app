import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'
    as webview_android;
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

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
        webview_android.AndroidWebViewController.enableDebugging(true);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        WebViewPlatform.instance ??= WebKitWebViewPlatform();
      }
    }
    _initialized = true;
  }

  static bool isKuulaUrl(String url) {
    return url.toLowerCase().contains('kuula.co');
  }

  static String buildKuulaHtml(String url) {
    final sanitized = url.trim();
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
      allow="xr-spatial-tracking; gyroscope; accelerometer"
      allowfullscreen
      scrolling="no"
      src="$sanitized"
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
  }) {
    final controller = WebViewController.fromPlatformCreationParams(
      _createParams(),
    );
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: onPageStarted,
          onPageFinished: onPageFinished,
          onWebResourceError: onWebResourceError,
          onProgress: onProgress,
        ),
      );

    if (controller.platform is webview_android.AndroidWebViewController) {
      final androidController =
          controller.platform as webview_android.AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    return controller;
  }

  static Future<void> load(String url, WebViewController controller) async {
    if (url.isEmpty) return;
    if (isKuulaUrl(url)) {
      await controller.loadHtmlString(buildKuulaHtml(url));
    } else {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await controller.loadRequest(uri);
      }
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
