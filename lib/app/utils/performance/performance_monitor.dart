import 'package:get/get.dart';
import '../logger/app_logger.dart';

/// Per-screen API-call counters alongside elapsed histograms.
///
/// Usage:
///   PerformanceMonitor.I.recordCount('provider.GET');
///   PerformanceMonitor.I.recordCount('provider.GET.200');
///   final calls = PerformanceMonitor.I.countSummary('provider.GET');
///   final top = PerformanceMonitor.I.topOperations(limit: 5);
///   AppLogger.info('calls=$calls top=$top');
class PerformanceMonitor extends GetxService {
  static PerformanceMonitor get I => Get.find<PerformanceMonitor>();

  /// Per-operation elapsed-ms samples for histogram-style reporting.
  /// Bounded at [_maxSamplesPerOperation] entries per key (ring drop of the
  /// oldest) so long sessions cannot grow memory without bound.
  static const int _maxSamplesPerOperation = 100;
  final Map<String, List<int>> _elapsedMsByOperation = {};

  /// Per-operation call counts for per-screen burn attribution.
  /// Bounded at [_maxCountedOperations] distinct keys (oldest evicted first)
  /// so long sessions cannot grow memory without bound.
  static const int _maxCountedOperations = 100;
  final Map<String, int> _countsByOperation = {};

  PerformanceSpan startSpan(String name) => PerformanceSpan._(name);

  /// Records one elapsed-ms sample for [operation] (e.g. 'GET /listings').
  ///
  /// How to instrument BaseProvider._executeWithRetry (wire-up NOT done
  /// here — this file only provides the helper):
  ///   final stopwatch = Stopwatch()..start();
  ///   try {
  ///     final response = await operation();
  ///     // ... existing retry logic ...
  ///     return response;
  ///   } finally {
  ///     stopwatch.stop();
  ///     // Guard with isRegistered when the service may be absent:
  ///     PerformanceMonitor.I.recordElapsed(
  ///         '$method $url', stopwatch.elapsedMilliseconds);
  ///   }
  /// Recording in `finally` (not just on success) keeps the histogram
  /// honest about retries and failures. Suggested buckets when exporting:
  /// `<100ms`, `<300ms`, `<1s`, `<3s`, `>=3s`. Read back via [elapsedSummary].
  void recordElapsed(String operation, int elapsedMs) {
    final samples = _elapsedMsByOperation.putIfAbsent(operation, () => []);
    samples.add(elapsedMs);
    if (samples.length > _maxSamplesPerOperation) {
      samples.removeRange(0, samples.length - _maxSamplesPerOperation);
    }
  }

  /// Records one call for [operation] (e.g. 'provider.GET').
  ///
  /// Bounded to [_maxCountedOperations] distinct operations; when full the
  /// oldest-inserted key is evicted first.
  void recordCount(String operation) {
    if (!_countsByOperation.containsKey(operation) &&
        _countsByOperation.length >= _maxCountedOperations) {
      _countsByOperation.remove(_countsByOperation.keys.first);
    }
    _countsByOperation.update(operation, (v) => v + 1, ifAbsent: () => 1);
  }

  /// Returns the recorded call count for [operation], or 0 when none yet.
  int countSummary(String operation) {
    return _countsByOperation[operation] ?? 0;
  }

  /// Returns the highest-count operations first, capped at [limit] entries.
  List<MapEntry<String, int>> topOperations({int limit = 10}) {
    final entries = _countsByOperation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.length > limit) return entries.sublist(0, limit);
    return entries;
  }

  /// Returns `{'count', 'avgMs', 'maxMs'}` for [operation], or null when no
  /// samples were recorded yet.
  Map<String, num>? elapsedSummary(String operation) {
    final samples = _elapsedMsByOperation[operation];
    if (samples == null || samples.isEmpty) return null;
    var total = 0;
    var max = samples.first;
    for (final s in samples) {
      total += s;
      if (s > max) max = s;
    }
    return {
      'count': samples.length,
      'avgMs': total / samples.length,
      'maxMs': max,
    };
  }

  /// Clears recorded samples (all operations, or one when given).
  void clearElapsed([String? operation]) {
    if (operation == null) {
      _elapsedMsByOperation.clear();
    } else {
      _elapsedMsByOperation.remove(operation);
    }
  }
}

class PerformanceSpan {
  PerformanceSpan._(this.name);
  final String name;
  final DateTime _start = DateTime.now();

  void end() {
    final elapsed = DateTime.now().difference(_start);
    AppLogger.info('Perf[$name] took ${elapsed.inMilliseconds}ms');
  }
}
