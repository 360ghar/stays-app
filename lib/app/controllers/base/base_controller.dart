import 'dart:async';

import 'package:get/get.dart';

import '../../utils/helpers/error_handler.dart';
import '../../utils/logger/app_logger.dart';
import '../../utils/performance/performance_monitor.dart';

/// BaseController provides common lifecycle helpers for all controllers.
/// - Automatic tracking/disposal of StreamSubscriptions and Workers
/// - Centralized error handling
/// - Lightweight performance tracing hooks
abstract class BaseController extends GetxController {
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<Worker> _workers = [];

  PerformanceSpan? _initSpan;

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

  /// Handle and surface an error consistently.
  void handleError(dynamic error, [StackTrace? stackTrace]) {
    AppLogger.error('Controller error', error, stackTrace);
    ErrorHandler.handleError(error);
  }

  @override
  void onInit() {
    super.onInit();
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
    for (final s in _subscriptions) {
      try {
        s.cancel();
      } catch (_) {}
    }
    _subscriptions.clear();
    for (final w in _workers) {
      try {
        w.dispose();
      } catch (_) {}
    }
    _workers.clear();
    super.onClose();
  }
}

