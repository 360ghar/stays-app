import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../utils/logger/app_logger.dart';

/// Service for crash reporting and error tracking.
///
/// This is a scaffolding service that can be extended with Firebase Crashlytics
/// or other crash reporting solutions (Sentry, Bugsnag, etc.).
///
/// To integrate Firebase Crashlytics:
/// 1. Add firebase_crashlytics to pubspec.yaml
/// 2. Configure Firebase in your project
/// 3. Uncomment the Crashlytics integration code below
class CrashReportingService extends GetxService {
  static CrashReportingService get I => Get.find<CrashReportingService>();

  bool _isInitialized = false;
  final RxBool isEnabled = false.obs;

  /// Initialize crash reporting
  Future<CrashReportingService> init() async {
    if (_isInitialized) return this;

    try {
      // Only enable in production
      isEnabled.value = AppConfig.isProduction;

      if (isEnabled.value) {
        await _initializeCrashlytics();
        _setupFlutterErrorHandling();
        _setupZoneErrorHandling();
      }

      _isInitialized = true;
      AppLogger.info(
        'CrashReportingService initialized. Enabled: ${isEnabled.value}',
      );
    } catch (e) {
      AppLogger.warning('Failed to initialize crash reporting: $e');
    }

    return this;
  }

  /// Initialize Firebase Crashlytics (placeholder)
  Future<void> _initializeCrashlytics() async {
    // TODO: Uncomment when firebase_crashlytics is added
    // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }

  /// Set up Flutter error handling
  void _setupFlutterErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      recordFlutterError(details);
    };
  }

  /// Set up zone error handling for async errors
  void _setupZoneErrorHandling() {
    // This should be called in main() using runZonedGuarded
    // See the example in the class documentation
  }

  /// Record a Flutter error
  void recordFlutterError(FlutterErrorDetails details) {
    if (!isEnabled.value) {
      AppLogger.error('Flutter error', details.exception, details.stack);
      return;
    }

    // TODO: Uncomment when firebase_crashlytics is added
    // FirebaseCrashlytics.instance.recordFlutterFatalError(details);

    AppLogger.error('Flutter error recorded', details.exception, details.stack);
  }

  /// Record a non-fatal error
  Future<void> recordError(
    dynamic error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    if (!isEnabled.value) {
      AppLogger.error(reason ?? 'Error', error, stackTrace);
      return;
    }

    // TODO: Uncomment when firebase_crashlytics is added
    // await FirebaseCrashlytics.instance.recordError(
    //   error,
    //   stackTrace ?? StackTrace.current,
    //   reason: reason,
    //   fatal: fatal,
    // );

    AppLogger.error(reason ?? 'Error recorded', error, stackTrace);
  }

  /// Set a custom key-value pair for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!isEnabled.value) return;

    // TODO: Uncomment when firebase_crashlytics is added
    // await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Set the user identifier for crash reports
  Future<void> setUserId(String? userId) async {
    if (!isEnabled.value) return;

    // TODO: Uncomment when firebase_crashlytics is added
    // await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');

    AppLogger.info('Crash reporting user ID set: ${userId ?? "cleared"}');
  }

  /// Log a message to be included in crash reports
  Future<void> log(String message) async {
    if (!isEnabled.value) return;

    // TODO: Uncomment when firebase_crashlytics is added
    // await FirebaseCrashlytics.instance.log(message);
  }

  /// Force a crash (for testing purposes only)
  void testCrash() {
    if (kDebugMode) {
      // TODO: Uncomment when firebase_crashlytics is added
      // FirebaseCrashlytics.instance.crash();
      throw Exception('Test crash from CrashReportingService');
    }
  }
}

/// Extension to make it easy to report errors from anywhere
extension CrashReportingExtension on Object {
  /// Report this error to crash reporting service
  void reportToCrashlytics({
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) {
    if (Get.isRegistered<CrashReportingService>()) {
      Get.find<CrashReportingService>().recordError(
        this,
        stackTrace: stackTrace,
        reason: reason,
        fatal: fatal,
      );
    }
  }
}
