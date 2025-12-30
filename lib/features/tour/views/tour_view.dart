import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'package:stays_app/app/utils/helpers/webview_helper.dart';
import 'package:stays_app/features/tour/controllers/tour_controller.dart';

class TourView extends GetView<TourController> {
  const TourView({super.key});

  Widget _buildWebView(BuildContext context) {
    PlatformWebViewWidgetCreationParams params =
        PlatformWebViewWidgetCreationParams(
          controller: controller.webViewController.platform,
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
            displayWithHybridComposition: true,
          );
    }
    return WebViewWidget.fromPlatformCreationParams(params: params);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('360 Virtual Tour'),
        actions: [
          IconButton(
            tooltip: 'Fullscreen hint',
            onPressed: () {
              Get.snackbar(
                'Fullscreen mode',
                'Rotate your device for the best experience.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            icon: const Icon(Icons.fullscreen),
          ),
          IconButton(
            tooltip: 'Share',
            onPressed: () {
              final url = controller.tourUrl.value;
              if (url?.isNotEmpty == true) {
                Get.snackbar(
                  'Share tour',
                  'Tour link copied to clipboard.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } else {
                Get.snackbar(
                  'Share tour',
                  'No tour link available.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Obx(() {
        final url = controller.tourUrl.value;
        if (url == null || url.isEmpty) {
          return Center(
            child: Text(
              'Virtual tour not available for this property.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (controller.hasError.value) {
          return Center(
            child: WebViewHelper.buildErrorWidget(
              onRetry: controller.reload,
              url: url,
            ),
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: _buildWebView(context),
              ),
            ),
            if (controller.progress.value > 0 &&
                controller.progress.value < 100)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: controller.progress.value / 100,
                  minHeight: 2,
                ),
              ),
            if (controller.isLoading.value)
              Container(
                color: colorScheme.surface.withValues(alpha: 0.65),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Loading 360 virtual tour...',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
