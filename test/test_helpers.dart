import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';


/// Test helper utilities for the application
class TestHelpers {
  /// Initialize GetX for testing
  static void initGetX() {
    Get.testMode = true;
    Get.reset();
  }

  /// Create a test widget wrapped with MaterialApp and GetMaterialApp
  static Widget createTestWidget(Widget child) {
    return GetMaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// Create a test widget with custom app
  static Widget createTestApp({
    Widget? home,
    String? initialRoute,
    Map<String, Widget Function(BuildContext)> routes = const {},
  }) {
    assert(home != null || initialRoute != null,
        'Either home or initialRoute must be provided');
    assert(!(home != null && initialRoute != null),
        'Cannot provide both home and initialRoute');
    return GetMaterialApp(
      home: initialRoute == null ? home : null,
      initialRoute: initialRoute,
      routes: routes,
    );
  }

  /// Find widget by type with optional finder
  static Finder findWidget<T extends Widget>() {
    return find.byType(T);
  }

  /// Find widget by key
  static Finder findByKey(Key key) {
    return find.byKey(key);
  }

  /// Find widget by text
  static Finder findByText(String text) {
    return find.text(text);
  }

  /// Find widget containing text
  static Finder findContainingText(String text) {
    return find.textContaining(text);
  }

  /// Tap widget and wait for navigation or loading
  static Future<void> tapAndWait(Finder finder, WidgetTester tester, {Duration? delay}) async {
    await tester.tap(finder);
    await tester.pumpAndSettle(delay ?? const Duration(milliseconds: 500));
  }

  /// Enter text into text field
  static Future<void> enterText(Finder finder, String text, WidgetTester tester) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Scroll to find widget
  static Future<void> scrollToFind(Finder finder, WidgetTester tester) async {
    await tester.scrollUntilVisible(
      finder,
      500,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
  }

  /// Verify if widget exists
  static bool widgetExists(Finder finder) {
    return finder.evaluate().isNotEmpty;
  }

  /// Get text from widget
  static String getText(Finder finder, WidgetTester tester) {
    final widget = tester.widget(finder);
    if (widget is Text) {
      return widget.data ?? widget.textSpan?.toPlainText() ?? '';
    }
    if (widget is EditableText) {
      return widget.controller.text;
    }
    throw TestFailure('Widget is not a Text or EditableText widget');
  }

  /// Verify if a button widget is enabled.
  /// Supports ElevatedButton, TextButton, OutlinedButton, and IconButton.
  static bool isWidgetEnabled(Finder finder, WidgetTester tester) {
    final widget = tester.widget(finder);
    if (widget is ElevatedButton) return widget.onPressed != null;
    if (widget is TextButton) return widget.onPressed != null;
    if (widget is OutlinedButton) return widget.onPressed != null;
    if (widget is IconButton) return widget.onPressed != null;
    throw ArgumentError('Widget type ${widget.runtimeType} is not supported');
  }

  /// Clean up after test
  static Future<void> cleanup() async {
    Get.reset();
  }
}

/// Mock data factories for testing
class MockDataFactory {
  /// Create mock property for testing
  static Map<String, dynamic> createMockProperty({
    int id = 1,
    String name = 'Test Property',
    String description = 'A beautiful test property',
    double pricePerNight = 100.0,
    int bedrooms = 2,
    int bathrooms = 1,
    int maxGuests = 4,
    double rating = 4.5,
    int reviewsCount = 10,
    bool isFavorite = false,
    List<String>? amenities,
    List<String>? images,
  }) {
    return {
      'id': id,
      'title': name,
      'description': description,
      'daily_rate': pricePerNight,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'max_occupancy': maxGuests,
      'rating': rating,
      'reviews_count': reviewsCount,
      'is_favorite': isFavorite,
      'amenities': amenities ?? ['WiFi', 'Parking', 'Kitchen'],
      'images': images ?? ['https://example.com/image1.jpg'],
      'property_type': 'Apartment',
      'city': 'Test City',
      'country': 'Test Country',
    };
  }

  /// Create mock user for testing
  static Map<String, dynamic> createMockUser({
    int id = 1,
    String email = 'test@example.com',
    String fullName = 'Test User',
    String? phone = '+1234567890',
  }) {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
    };
  }
}

/// Test configurations
abstract class TestConfig {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration networkDelay = Duration(milliseconds: 500);
}

/// Performance testing utilities
class PerformanceTestHelpers {
  /// Measure widget build time
  static Future<Duration> measureBuildTime(Widget widget, WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    await tester.pumpWidget(TestHelpers.createTestWidget(widget));
    await tester.pump(); // Only pump one frame for build measurement

    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Benchmark multiple widget builds
  static Future<List<Duration>> benchmarkBuilds(
    Widget widget,
    int iterations, {
    Duration? delayBetweenBuilds,
    required WidgetTester tester,
  }) async {
    final durations = <Duration>[];

    for (int i = 0; i < iterations; i++) {
      // Reset the widget tree between iterations to avoid warm caches
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final duration = await measureBuildTime(widget, tester);
      durations.add(duration);

      if (delayBetweenBuilds != null) {
        await Future.delayed(delayBetweenBuilds);
      }
    }

    return durations;
  }

  /// Calculate average build time from benchmark results
  static Duration calculateAverage(List<Duration> durations) {
    if (durations.isEmpty) return Duration.zero;

    final totalMicroseconds = durations
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a + b);

    return Duration(microseconds: totalMicroseconds ~/ durations.length);
  }
}
