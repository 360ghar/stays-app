class AnalyticsService {
  final bool enabled;
  AnalyticsService({required this.enabled});

  void log(String event, [Map<String, dynamic>? params]) {
    if (!enabled) return;
    // Integrate analytics provider here
  }
}

