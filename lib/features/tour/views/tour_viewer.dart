import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'package:stays_app/app/utils/helpers/webview_helper.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/core/ui/async_state.dart';

/// Rebuilt 360 viewer. Fixes the legacy fake share (snackbar-only):
/// share now sends the real tour link via share_plus.
class TourViewer extends StatefulWidget {
  const TourViewer({super.key, this.initialUrl, this.title = '360 Tour'});
  final String? initialUrl;
  final String title;

  @override
  State<TourViewer> createState() => _TourViewerState();
}

class _TourViewerState extends State<TourViewer> {
  WebViewController? _controller;
  String? _url;
  bool _hasError = false;
  int _progress = 0;
  bool _hintShown = false;

  @override
  void initState() {
    super.initState();
    _url = _sanitize(widget.initialUrl);
    WebViewHelper.ensureInitialized();
    if (_url != null) _initController(_url!);
  }

  static String? _sanitize(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https') return null;
    return raw;
  }

  void _initController(String url) {
    late final WebViewController controller;
    controller = WebViewHelper.createController(
      onPageStarted: (_) {
        if (!mounted) return;
        setState(() => _hasError = false);
      },
      onProgress: (value) {
        if (!mounted) return;
        setState(() => _progress = value);
      },
      onPageFinished: (_) {
        unawaited(WebViewHelper.injectResponsiveStyles(controller));
      },
      onWebResourceError: (_) {
        if (!mounted) return;
        setState(() => _hasError = true);
      },
    );
    _controller = controller;
    unawaited(WebViewHelper.load(url, controller));
  }

  void _reload() {
    final url = _url;
    if (url == null) return;
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    final controller = _controller;
    if (controller != null) {
      unawaited(WebViewHelper.load(url, controller));
    } else {
      _initController(url);
    }
  }

  Future<void> _share() async {
    final url = _url;
    if (url == null || url.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(text: url, subject: widget.title),
    );
  }

  void _showHint() {
    if (_hintShown) return;
    _hintShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rotate your device for the best experience.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppPaths.explore);
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Fullscreen hint',
            onPressed: _showHint,
            icon: const Icon(Icons.fullscreen),
          ),
          IconButton(
            tooltip: 'Share tour',
            onPressed: url == null ? null : _share,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: _TourBody(
        url: url,
        hasError: _hasError,
        progress: _progress,
        controller: _controller,
        onRetry: _reload,
      ),
    );
  }
}

class _TourBody extends StatelessWidget {
  const _TourBody({
    required this.url,
    required this.hasError,
    required this.progress,
    required this.controller,
    required this.onRetry,
  });
  final String? url;
  final bool hasError;
  final int progress;
  final WebViewController? controller;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const AsyncState.empty(
        message: 'Virtual tour not available for this property.',
      );
    }
    if (hasError) {
      return Center(
        child: WebViewHelper.buildErrorWidget(onRetry: onRetry, url: url),
      );
    }
    final webController = controller;
    if (webController == null) {
      return const AsyncState.loading(message: 'Loading 360 tour…');
    }
    return Stack(
      children: [
        Positioned.fill(child: _PlatformWebView(controller: webController)),
        if (progress > 0 && progress < 100)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                StayTokens.accent,
              ),
            ),
          ),
      ],
    );
  }
}

class _PlatformWebView extends StatelessWidget {
  const _PlatformWebView({required this.controller});
  final WebViewController controller;

  @override
  Widget build(BuildContext context) {
    PlatformWebViewWidgetCreationParams params =
        PlatformWebViewWidgetCreationParams(
          controller: controller.platform,
          layoutDirection: Directionality.of(context),
        );
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      params =
          WebKitWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
            params,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      params =
          AndroidWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
            params,
          );
    }
    return WebViewWidget.fromPlatformCreationParams(params: params);
  }
}
