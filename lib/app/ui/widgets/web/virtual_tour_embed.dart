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
  bool _isFullscreen = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
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
      ..setBackgroundColor(Colors.black)
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
    }

    _controller.loadRequest(Uri.parse(widget.url));

    // iOS requires an explicit platform view initialization in some cases
    if (Platform.isAndroid) {
      // No-op: Android initialization handled by plugin
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _enterFullscreen() {
    if (_isFullscreen) return;
    _isFullscreen = true;
    _overlayEntry = OverlayEntry(
      builder: (ctx) => _FullscreenOverlay(
        controller: _controller,
        onClose: _exitFullscreen,
        onReload: () {
          setState(() {
            _hasError = false;
            _progress = 0;
          });
          _controller.reload();
        },
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    setState(() {});
  }

  void _exitFullscreen() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isFullscreen = false;
    if (mounted) setState(() {});
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
          if (!_isFullscreen) WebViewWidget(controller: _controller),
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
                    onPressed: _enterFullscreen,
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

class _FullscreenOverlay extends StatelessWidget {
  final WebViewController controller;
  final VoidCallback onClose;
  final VoidCallback onReload;

  const _FullscreenOverlay({
    required this.controller,
    required this.onClose,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Virtual Tour',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onReload,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(child: WebViewWidget(controller: controller)),
          ],
        ),
      ),
    );
  }
}
