import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/models/property_model.dart';
import '../../utils/helpers/webview_helper.dart';

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
    WebViewHelper.load(url, webViewController);
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
    WebViewHelper.load(url, webViewController);
  }

  void _resolveUrlFromArguments() {
    final args = Get.arguments;
    if (args is String) {
      tourUrl.value = args;
    } else if (args is Property) {
      tourUrl.value = args.virtualTourUrl;
    } else if (args is Map) {
      final dynamic value = args['url'] ?? args['virtualTourUrl'];
      if (value is String && value.isNotEmpty) {
        tourUrl.value = value;
      }
    }
  }
}
