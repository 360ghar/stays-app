import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class VirtualTourEmbed extends StatefulWidget {
  final String url;
  final double height;

  const VirtualTourEmbed({super.key, required this.url, this.height = 260});

  @override
  State<VirtualTourEmbed> createState() => _VirtualTourEmbedState();
}

class _VirtualTourEmbedState extends State<VirtualTourEmbed> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // Prefer Surface-based WebView on Android to avoid ImageReader buffer issues
    // For webview_flutter v4+, Surface composition is handled internally.
    // No manual platform override needed here.
    // Create controller with platform-specific params for better compatibility
    final PlatformWebViewControllerCreationParams baseParams =
        const PlatformWebViewControllerCreationParams();
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      final params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
      _controller = WebViewController.fromPlatformCreationParams(params);
    } else {
      _controller = WebViewController.fromPlatformCreationParams(baseParams);
    }

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Keep background consistent with light theme while page loads
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(
        // Modern mobile Safari UA improves compatibility with some 360 providers
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Mobile/15E148 Safari/604.1',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onNavigationRequest: (request) {
            // Keep navigation embedded; allow common in-app schemes used by tours.
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            const allowed = {'http', 'https', 'about', 'data', 'blob'};
            if (allowed.contains(uri.scheme))
              return NavigationDecision.navigate;
            return NavigationDecision.prevent; // block external app intents
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _hasError = true);
          },
        ),
      );

    // Android-specific tuning
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final AndroidWebViewController androidController =
          _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      // Try to minimize auto-darkening in WebView content (best-effort; API may be ignored on some versions)
      // Note: These methods are no-ops on unsupported Android versions.
      try {
        // Some plugin versions expose these; calls are guarded by try to avoid runtime errors.
        // ignore: deprecated_member_use_from_same_package
        // ignore: undefined_function
        // androidController.setForceDark(null);
      } catch (_) {}
    }

    _controller.loadRequest(Uri.parse(widget.url));
    _isInitializing = false;

    // iOS requires an explicit platform view initialization in some cases
    if (Platform.isAndroid) {
      // No-op: Android initialization handled by plugin
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _VirtualTourFullScreenPage(url: widget.url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _ErrorPlaceholder(
        onRetry: () {
          setState(() {
            _hasError = false;
            _progress = 0;
          });
          _controller.reload();
        },
      );
    }
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          if (!_hasError) WebViewWidget(controller: _controller),
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 2,
              backgroundColor: Colors.black.withValues(alpha: 0.05),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Full screen',
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: _openFullscreen,
                  ),
                  IconButton(
                    tooltip: 'Reload',
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _progress = 0;
                      });
                      _controller.reload();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorPlaceholder({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.public, size: 32, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('Unable to load virtual tour'),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VirtualTourFullScreenPage extends StatefulWidget {
  final String url;
  const _VirtualTourFullScreenPage({required this.url});

  @override
  State<_VirtualTourFullScreenPage> createState() => _VirtualTourFullScreenPageState();
}

class _VirtualTourFullScreenPageState extends State<_VirtualTourFullScreenPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // No explicit platform override needed for v4+.
    final PlatformWebViewControllerCreationParams baseParams =
        const PlatformWebViewControllerCreationParams();
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      final params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
      _controller = WebViewController.fromPlatformCreationParams(params);
    } else {
      _controller = WebViewController.fromPlatformCreationParams(baseParams);
    }
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 15_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Mobile/15E148 Safari/604.1')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) => setState(() => _progress = progress),
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            const allowed = {'http', 'https', 'about', 'data', 'blob'};
            return allowed.contains(uri.scheme)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onWebResourceError: (_) => setState(() => _hasError = true),
        ),
      );
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final AndroidWebViewController androidController =
          _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Tour'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: () {
              setState(() {
                _hasError = false;
                _progress = 0;
              });
              _controller.reload();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasError)
            const Center(child: Text('Unable to load virtual tour'))
          else
            WebViewWidget(controller: _controller),
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 2,
            ),
        ],
      ),
    );
  }
}
