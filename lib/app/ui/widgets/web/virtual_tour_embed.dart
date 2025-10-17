import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/helpers/webview_helper.dart';

class VirtualTourEmbed extends StatefulWidget {
  final String url;
  final double? height;
  final double aspectRatio;

  const VirtualTourEmbed({
    super.key,
    required this.url,
    this.height,
    this.aspectRatio = 4 / 5, // Default to 4:5 for taller/vertical look suitable for property tours
  });

  @override
  State<VirtualTourEmbed> createState() => _VirtualTourEmbedState();
}

class _VirtualTourEmbedState extends State<VirtualTourEmbed> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;
  @override
  void initState() {
    super.initState();
    WebViewHelper.ensureInitialized();
    _controller = WebViewHelper.createController(
      onPageStarted: (_) {
        if (!mounted) return;
        setState(() {
          _hasError = false;
          _progress = 0;
        });
      },
      onProgress: (value) {
        if (!mounted) return;
        setState(() => _progress = value);
      },
      onPageFinished: (_) async {
        await WebViewHelper.injectResponsiveStyles(_controller);
      },
      onWebResourceError: (_) {
        if (!mounted) return;
        setState(() => _hasError = true);
      },
      onNavigationRequest: (request) {
        final uri = Uri.tryParse(request.url);
        if (uri == null) {
          return NavigationDecision.prevent;
        }
        const allowedSchemes = {'http', 'https', 'about', 'data', 'blob'};
        return allowedSchemes.contains(uri.scheme)
            ? NavigationDecision.navigate
            : NavigationDecision.prevent;
      },
    )
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        Platform.isAndroid
            ? 'Mozilla/5.0 (Linux; Android 13; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36'
            : 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Mobile/15E148 Safari/604.1',
      );

    unawaited(_loadTour());
  }

  Future<void> _loadTour() async {
    await WebViewHelper.load(widget.url, _controller);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildWebView(BuildContext context) {
    PlatformWebViewWidgetCreationParams params =
        PlatformWebViewWidgetCreationParams(
          controller: _controller.platform,
          layoutDirection: Directionality.of(context),
        );
    if (Platform.isIOS) {
      params =
          WebKitWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
            params,
          );
    } else if (Platform.isAndroid) {
      // Use virtual display mode for smoother rendering of high-load tours.
      params = AndroidWebViewWidgetCreationParams
          .fromPlatformWebViewWidgetCreationParams(
        params,
        displayWithHybridComposition: false,
      );
    }
    return WebViewWidget.fromPlatformCreationParams(params: params);
  }

  void _openFullscreen() {
    Get.toNamed(Routes.tour, arguments: widget.url);
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
          unawaited(_loadTour());
        },
      );
    }

    final content = Stack(
      children: [
        if (!_hasError) _buildWebView(context),
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
                    unawaited(_loadTour());
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );

    // Use AspectRatio for broader look when height is not specified
    if (widget.height != null) {
      return SizedBox(
        height: widget.height,
        child: content,
      );
    } else {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: content,
      );
    }
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
