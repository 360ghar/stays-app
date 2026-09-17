import 'dart:async';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/utils/helpers/webview_helper.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class TourController extends GetxController {
  final RxnString tourUrl = RxnString();
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxInt progress = 0.obs;

  late final WebViewController webViewController;

  @override
  void onInit() {
    super.onInit();
    _resolveUrlFromArguments();
    WebViewHelper.ensureInitialized();
    final url = tourUrl.value;
    if (url == null || url.isEmpty) {
      hasError.value = true;
      isLoading.value = false;
      return;
    }
    webViewController = WebViewHelper.createController(
      onPageStarted: (_) {
        isLoading.value = true;
        hasError.value = false;
      },
      onProgress: (value) => progress.value = value,
      onPageFinished: (_) async {
        isLoading.value = false;
        await WebViewHelper.injectResponsiveStyles(webViewController);
      },
      onWebResourceError: (_) {
        hasError.value = true;
        isLoading.value = false;
      },
    );
    unawaited(WebViewHelper.load(url, webViewController));
  }

  void reload() {
    final url = tourUrl.value;
    if (url == null || url.isEmpty) {
      hasError.value = true;
      isLoading.value = false;
      return;
    }
    hasError.value = false;
    isLoading.value = true;
    progress.value = 0;
    unawaited(WebViewHelper.load(url, webViewController));
  }

  void _resolveUrlFromArguments() {
    final args = Get.arguments;
    String? resolved;
    if (args is String) {
      resolved = args;
    } else if (args is Property) {
      resolved = args.virtualTourUrl;
    } else if (args is Map) {
      final dynamic value = args['url'] ?? args['virtualTourUrl'];
      if (value is String && value.isNotEmpty) {
        resolved = value;
      }
    }
    // Only https tour URLs may be loaded (WebViewHelper enforces this too).
    final uri = resolved == null ? null : Uri.tryParse(resolved);
    if (resolved != null && uri != null && uri.scheme == 'https') {
      tourUrl.value = resolved;
    } else if (resolved != null) {
      AppLogger.warning('Rejected non-https tour URL from arguments');
    }
  }
}
