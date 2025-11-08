import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Widget performance optimization utilities
class WidgetOptimizer {
  /// Optimize list view performance with proper builders
  static Widget optimizedListView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ScrollController? controller,
    EdgeInsets? padding,
    double? itemExtent,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemExtent: itemExtent,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      cacheExtent: kIsWeb ? 0 : 500, // Optimize for web/mobile
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }

  /// Optimized grid view builder
  static Widget optimizedGridView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsets? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      cacheExtent: kIsWeb ? 0 : 500,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }

  /// Optimized page view builder
  static Widget optimizedPageView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    PageController? controller,
    void Function(int)? onPageChanged,
    ScrollPhysics? physics,
  }) {
    return PageView.builder(
      controller: controller,
      onPageChanged: onPageChanged,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }

  /// Wrap expensive widgets with performance boundary
  static Widget performanceBoundary({required Widget child}) {
    return RepaintBoundary(
      child: child,
    );
  }

  /// Create optimized image widget with proper loading and error handling
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Note: when width/height are null, Flutter caches full-resolution images.
    // Callers should prefer passing dimensions. If null, we let framework decide.
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildDefaultLoadingPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildDefaultErrorWidget();
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );
  }

  static Widget _buildDefaultLoadingPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  static Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }

  /// Optimized text widget with proper overflow handling
  static Widget optimizedText(
    String text, {
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign? textAlign,
    bool softWrap = true,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      textAlign: textAlign,
      softWrap: softWrap,
    );
  }

  /// Memoized widget builder for expensive computations
  static Widget memoize(Widget Function() builder) {
    return _MemoizedWidget(builder: builder);
  }
}

/// Memoized widget that rebuilds only when necessary
class _MemoizedWidget extends StatefulWidget {
  final Widget Function() builder;

  const _MemoizedWidget({required this.builder});

  @override
  State<_MemoizedWidget> createState() => _MemoizedWidgetState();
}

class _MemoizedWidgetState extends State<_MemoizedWidget> {
  Widget? _cachedWidget;

  @override
  Widget build(BuildContext context) {
    _cachedWidget ??= widget.builder();
    return _cachedWidget!;
  }

  @override
  void didUpdateWidget(_MemoizedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Invalidate cache if builder function changes
    if (oldWidget.builder != widget.builder) {
      _cachedWidget = null;
    }
  }
}

/// Performance metrics tracking
class PerformanceMetrics {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<int>> _renderTimes = {};
  static const int _maxOperations = 100;

  /// Start measuring performance for an operation
  static void startMeasure(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  /// End measuring performance for an operation
  static void endMeasure(String operation) {
    final startTime = _startTimes[operation];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      final milliseconds = duration.inMilliseconds;

      _renderTimes.putIfAbsent(operation, () => []).add(milliseconds);
      _startTimes.remove(operation);

      // Keep only last 100 measurements per operation
      final times = _renderTimes[operation]!;
      if (times.length > 100) {
        times.removeAt(0);
      }

      // Cap total unique operations to prevent unbounded growth
      if (_renderTimes.length > _maxOperations) {
        final oldestKey = _renderTimes.keys.first;
        _renderTimes.remove(oldestKey);
        _startTimes.remove(oldestKey);
      }

      if (kDebugMode) {
        debugPrint('Performance: $operation took ${milliseconds}ms');
      }
    }
  }

  /// Get average render time for an operation
  static double? getAverageTime(String operation) {
    final times = _renderTimes[operation];
    if (times == null || times.isEmpty) return null;

    return times.reduce((a, b) => a + b) / times.length;
  }

  /// Get all performance metrics
  static Map<String, double> getAllMetrics() {
    return _renderTimes.map((key, times) {
      if (times.isEmpty) return MapEntry(key, 0.0);
      return MapEntry(
        key,
        times.reduce((a, b) => a + b) / times.length,
      );
    });
  }

  /// Clear all metrics
  static void clearMetrics() {
    _startTimes.clear();
    _renderTimes.clear();
  }
}

/// Widget performance analyzer
class WidgetPerformanceAnalyzer {
  /// Analyze widget build performance
  static Widget analyzePerformance({
    required String widgetName,
    required Widget child,
  }) {
    return _PerformanceWrapper(
      widgetName: widgetName,
      child: child,
    );
  }
}

class _PerformanceWrapper extends StatefulWidget {
  final String widgetName;
  final Widget child;

  const _PerformanceWrapper({
    required this.widgetName,
    required this.child,
  });

  @override
  State<_PerformanceWrapper> createState() => _PerformanceWrapperState();
}

class _PerformanceWrapperState extends State<_PerformanceWrapper> {
  bool _initMeasured = false;
  @override
  void initState() {
    super.initState();
    PerformanceMetrics.startMeasure('${widget.widgetName}_init');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initMeasured) {
        PerformanceMetrics.endMeasure('${widget.widgetName}_init');
        _initMeasured = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    PerformanceMetrics.startMeasure('${widget.widgetName}_build');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PerformanceMetrics.endMeasure('${widget.widgetName}_build');
    });
    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Intentionally left empty; init measurement ends post-frame once.
  }
}
