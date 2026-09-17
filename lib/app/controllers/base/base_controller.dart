import 'dart:async';

import 'package:get/get.dart';

import '../../utils/logger/app_logger.dart';
import '../../utils/performance/performance_monitor.dart';
import '../../utils/services/error_service.dart';

/// BaseController provides common lifecycle helpers for all controllers.
/// - Automatic tracking/disposal of StreamSubscriptions and Workers
/// - Centralized error handling with ErrorService integration
/// - Lightweight performance tracing hooks
/// - State management utilities
/// - Memory leak prevention
abstract class BaseController extends GetxController {
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<Worker> _workers = [];
  final List<Completer<void>> _completers = [];

  PerformanceSpan? _initSpan;
  late final ErrorService _errorService;

  /// Loading state for the controller
  final RxBool isLoading = false.obs;

  /// Error message for the controller
  final RxString errorMessage = ''.obs;

  /// Registers a subscription that will be cancelled on [onClose].
  T trackSubscription<T extends StreamSubscription>(T sub) {
    _subscriptions.add(sub);
    return sub;
  }

  /// Registers a worker that will be disposed on [onClose].
  T trackWorker<T extends Worker>(T worker) {
    _workers.add(worker);
    return worker;
  }

  /// Registers a completer that will be completed on [onClose].
  Completer<void> trackCompleter<T>(Completer<void> completer) {
    _completers.add(completer);
    return completer;
  }

  /// Handle and surface an error consistently with ErrorService integration.
  void handleError(dynamic error, [StackTrace? stackTrace]) {
    final context = runtimeType.toString();
    AppLogger.error('Controller error in $context', error, stackTrace);

    // Set error message for UI
    errorMessage.value = _errorService.getErrorMessage(error);

    // Handle error through ErrorService for consistent logging and reporting
    _errorService.handleError(error, stackTrace, context);
  }

  /// Execute a function with loading state and error handling.
  ///
  /// Returns the operation's value, or null when the operation threw (the
  /// error is already surfaced via [handleError] unless [swallowError]).
  /// Null therefore means failure — with one caveat: it is ambiguous with an
  /// operation that legitimately returns null. Callers that need to tell
  /// "failed" apart from "null result" must try/catch the operation
  /// themselves instead of using this helper.
  Future<T?> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    bool showLoading = true,
    String? loadingMessage,
    bool swallowError = false,
  }) async {
    try {
      if (showLoading) {
        isLoading.value = true;
        errorMessage.value = '';
      }

      return await operation();
    } catch (error, stackTrace) {
      if (!swallowError) {
        handleError(error, stackTrace);
      }
      return null;
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  /// Clear error state
  void clearError() {
    errorMessage.value = '';
  }

  @override
  void onInit() {
    super.onInit();
    _errorService = Get.find<ErrorService>();
    _initSpan = PerformanceMonitor.I.startSpan(runtimeType.toString());
  }

  @override
  void onReady() {
    super.onReady();
    _initSpan?.end();
    _initSpan = null;
  }

  @override
  void onClose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      try {
        unawaited(subscription.cancel());
      } catch (error) {
        AppLogger.warning('Error canceling subscription: $error');
      }
    }
    _subscriptions.clear();

    // Dispose all workers
    for (final worker in _workers) {
      try {
        worker.dispose();
      } catch (error) {
        AppLogger.warning('Error disposing worker: $error');
      }
    }
    _workers.clear();

    // Complete all completers
    for (final completer in _completers) {
      if (!completer.isCompleted) {
        try {
          completer.complete();
        } catch (error) {
          AppLogger.warning('Error completing completer: $error');
        }
      }
    }
    _completers.clear();

    super.onClose();
  }
}
