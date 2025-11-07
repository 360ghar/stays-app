import 'package:get/get.dart';
import '../logger/app_logger.dart';

class PerformanceMonitor extends GetxService {
  static PerformanceMonitor get I => Get.find<PerformanceMonitor>();

  PerformanceSpan startSpan(String name) => PerformanceSpan._(name);
}

class PerformanceSpan {
  final String name;
  final DateTime _start = DateTime.now();

  PerformanceSpan._(this.name);

  void end() {
    final elapsed = DateTime.now().difference(_start);
    AppLogger.info('Perf[$name] took ${elapsed.inMilliseconds}ms');
  }
}

