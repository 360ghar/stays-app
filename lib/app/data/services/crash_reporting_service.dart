import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../../config/app_config.dart';
import '../../utils/logger/app_logger.dart';

/// Service for crash reporting and error tracking using Firebase Crashlytics.
///
/// This service automatically captures Flutter errors and can be used to
/// record custom errors, set user context, and log breadcrumbs.
///
/// Shared singleton: every caller reports into the one Crashlytics hook.
class CrashReportingService {
  factory CrashReportingService() => _shared;
  CrashReportingService._internal();

  static final CrashReportingService _shared =
      CrashReportingService._internal();

  static CrashReportingService get I => _shared;

  bool _isInitialized = false;
  final ValueNotifier<bool> isEnabled = ValueNotifier<bool>(false);

  FirebaseCrashlytics? _crashlytics;

  /// Initialize crash reporting
  Future<CrashReportingService> init() async {
    if (_isInitialized) return this;

    try {
      // Crashlytics needs a Firebase app; only the prod entry point makes one.
      isEnabled.value = !AppConfig.isDev && Firebase.apps.isNotEmpty;

      if (isEnabled.value) {
        _crashlytics = FirebaseCrashlytics.instance;
        await _initializeCrashlytics();
        _setupFlutterErrorHandling();
      }

      _isInitialized = true;
      AppLogger.info(
        'CrashReportingService initialized. Enabled: ${isEnabled.value}',
      );
    } catch (e, stack) {
      AppLogger.warning('Failed to initialize crash reporting: $e');
      // Don't let crash reporting initialization crash the app
      if (kDebugMode) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: e,
            stack: stack,
            library: 'CrashReportingService',
            context: ErrorDescription('Failed to initialize Crashlytics'),
          ),
        );
      }
    }

    return this;
  }

  /// Initialize Firebase Crashlytics
  Future<void> _initializeCrashlytics() async {
    if (_crashlytics == null) return;

    // Enable crash collection
    await _crashlytics!.setCrashlyticsCollectionEnabled(true);

    // Set custom keys for debugging
    await _crashlytics!.setCustomKey('environment', AppConfig.I.environment);
    await _crashlytics!.setCustomKey(
      'api_base_url',
      AppConfig.I.api.apiBaseUrl,
    );
  }

  /// Set up Flutter error handling
  void _setupFlutterErrorHandling() {
    // Capture Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      // Always present the error in debug mode
      FlutterError.presentError(details);

      // Record to Crashlytics
      recordFlutterError(details);
    };

    // Capture errors from the platform dispatcher
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(recordError(error, stackTrace: stack, fatal: true));
      return true;
    };
  }

  /// Record a Flutter error
  void recordFlutterError(FlutterErrorDetails details) {
    if (!isEnabled.value || _crashlytics == null) {
      AppLogger.error('Flutter error', details.exception, details.stack);
      return;
    }

    // Record as fatal error
    unawaited(_crashlytics!.recordFlutterFatalError(details));
    AppLogger.error(
      'Flutter error recorded to Crashlytics',
      details.exception,
      details.stack,
    );
  }

  /// Record a non-fatal error
  Future<void> recordError(
    dynamic error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    if (!isEnabled.value || _crashlytics == null) {
      AppLogger.error(reason ?? 'Error', error, stackTrace);
      return;
    }

    await _crashlytics!.recordError(
      error,
      stackTrace ?? StackTrace.current,
      reason: reason,
      fatal: fatal,
    );

    AppLogger.error(
      reason ?? 'Error recorded to Crashlytics',
      error,
      stackTrace,
    );
  }

  /// Set a custom key-value pair for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!isEnabled.value || _crashlytics == null) return;

    await _crashlytics!.setCustomKey(key, value);
  }

  /// Set the user identifier for crash reports
  Future<void> setUserId(String? userId) async {
    if (!isEnabled.value || _crashlytics == null) return;

    await _crashlytics!.setUserIdentifier(userId ?? '');
    AppLogger.info('Crash reporting user ID set: ${userId ?? "cleared"}');
  }

  /// Log a message to be included in crash reports
  Future<void> log(String message) async {
    if (!isEnabled.value || _crashlytics == null) return;

    await _crashlytics!.log(message);
  }

  /// Force a crash (for testing purposes only)
  void testCrash() {
    if (kDebugMode) {
      _crashlytics?.crash();
    }
  }

  /// Check if crash reporting is properly configured
  bool get isConfigured => _crashlytics != null && isEnabled.value;
}

/// Extension to make it easy to report errors from anywhere
extension CrashReportingExtension on Object {
  /// Report this error to crash reporting service
  void reportToCrashlytics({
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) {
    // Degrades to a log when crash reporting is disabled/uninitialized.
    unawaited(
      CrashReportingService().recordError(
        this,
        stackTrace: stackTrace,
        reason: reason,
        fatal: fatal,
      ),
    );
  }
}
