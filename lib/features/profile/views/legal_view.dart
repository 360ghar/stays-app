import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:stays_app/app/utils/constants/app_constants.dart';
import 'package:stays_app/app/utils/helpers/webview_helper.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class LegalView extends StatefulWidget {
  const LegalView({super.key});

  @override
  State<LegalView> createState() => _LegalViewState();
}

class _LegalViewState extends State<LegalView> {
  static const Map<String, _LegalDocument> _documents = {
    'terms': _LegalDocument(
      title: 'Terms of Service',
      url: AppConstants.termsOfServiceUrl,
    ),
    'privacy': _LegalDocument(
      title: 'Privacy Policy',
      url: AppConstants.privacyPolicyUrl,
    ),
  };

  late final WebViewController _controller;
  late final _LegalDocument _doc;

  bool _isLoading = true;
  bool _hasError = false;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _doc = _resolveDocument();
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
      onPageFinished: (_) {
        if (!mounted) return;
        setState(() => _isLoading = false);
      },
      onWebResourceError: (_) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      },
      onNavigationRequest: (request) {
        // Keep the user inside the app for any links on the same host.
        // External links (e.g., a payment processor) are opened in the system browser.
        final currentHost = Uri.tryParse(_doc.url)?.host ?? '';
        final requestedHost = Uri.tryParse(request.url)?.host ?? '';
        if (requestedHost.isNotEmpty && requestedHost != currentHost) {
          unawaited(_openExternal(request.url));
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    );

    unawaited(_controller.setBackgroundColor(Colors.white));
    unawaited(_controller.enableZoom(true));

    unawaited(WebViewHelper.load(_doc.url, _controller));
  }

  _LegalDocument _resolveDocument() {
    final raw = Get.arguments;
    final slug = raw is String ? raw.toLowerCase() : 'terms';
    final key = _documents.keys.firstWhere(
      (k) => slug == k || slug == '$k-policy' || slug == '${k}s',
      orElse: () => 'terms',
    );
    return _documents[key]!;
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      AppLogger.error('Failed to open external URL: $e');
    }
  }

  Future<void> _reload() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _progress = 0;
    });
    await WebViewHelper.load(_doc.url, _controller);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_doc.title)),
      body: Stack(
        children: [
          if (_hasError)
            _ErrorPlaceholder(onRetry: _reload)
          else
            WebViewWidget(controller: _controller),
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
          if (_isLoading && !_hasError)
            Container(
              color: colors.surface.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_controller.loadHtmlString(''));
    super.dispose();
  }
}

class _LegalDocument {
  const _LegalDocument({required this.title, required this.url});

  final String title;
  final String url;
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.public_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Unable to load this page'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
