import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../routes/app_routes.dart';
import '../../../utils/helpers/webview_helper.dart';

class VirtualTourEmbed extends StatefulWidget {
  const VirtualTourEmbed({super.key, required this.tourUrl});

  final String tourUrl;

  @override
  State<VirtualTourEmbed> createState() => _VirtualTourEmbedState();
}

class _VirtualTourEmbedState extends State<VirtualTourEmbed> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  int _progress = 0;

  static final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
        Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
      };

  @override
  void initState() {
    super.initState();

    WebViewHelper.ensureInitialized();

    _controller = WebViewHelper.createController(
      onPageStarted: (_) {
        if (!mounted) return;
        setState(() {
          _isLoading = true;
          _hasError = false;
          _progress = 0;
        });
      },
      onProgress: (value) {
        if (!mounted) return;
        setState(() => _progress = value);
      },
      onPageFinished: (_) async {
        if (!mounted) return;
        setState(() => _isLoading = false);
        await WebViewHelper.injectResponsiveStyles(_controller);
      },
      onWebResourceError: (_) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      },
    );

    _controller
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(false);

    WebViewHelper.load(widget.tourUrl, _controller);
  }

  Future<void> _reload() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _progress = 0;
    });
    await WebViewHelper.load(widget.tourUrl, _controller);
  }

  Widget _buildWebView(BuildContext context) {
    PlatformWebViewWidgetCreationParams params =
        PlatformWebViewWidgetCreationParams(
          controller: _controller.platform,
          layoutDirection: Directionality.of(context),
          gestureRecognizers: _gestureRecognizers,
        );

    if (!kIsWeb && Platform.isIOS) {
      params =
          WebKitWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
            params,
          );
    } else if (!kIsWeb && Platform.isAndroid) {
      params =
          AndroidWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
            params,
            displayWithHybridComposition: true,
          );
    }

    return WebViewWidget.fromPlatformCreationParams(params: params);
  }

  void _openFullscreen() {
    Get.toNamed(Routes.tour, arguments: widget.tourUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _ErrorPlaceholder(onRetry: _reload);
    }

    return Stack(
      children: [
        _buildWebView(context),
        if (_progress > 0 && _progress < 100)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 2,
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
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
                  onPressed: _reload,
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.05),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({required this.onRetry});

  final VoidCallback onRetry;

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
