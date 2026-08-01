import 'package:logger/logger.dart';

import '../../../config/app_config.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 80,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: _getLogLevel(),
  );

  static Level _getLogLevel() {
    try {
      if (AppConfig.isProduction) return Level.warning;
      if (AppConfig.isStaging) return Level.info;
    } catch (_) {
      // AppConfig not configured yet (early startup / unit tests): fall back
      // to trace so logging never crashes before configuration is set.
    }
    return Level.trace;
  }

  static void debug(String message, [dynamic data]) =>
      _logger.d(_fmt(message, data));
  static void info(String message, [dynamic data]) =>
      _logger.i(_fmt(message, data));
  static void warning(String message, [dynamic data]) =>
      _logger.w(_fmt(message, data));
  static void error(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(_fmt(message, error), error: error, stackTrace: stackTrace);

  static void logRequest(dynamic request) =>
      _logger.d(_fmt('API Request', request));
  static void logResponse(dynamic response) =>
      _logger.d(_fmt('API Response', response));

  static String _fmt(String message, [dynamic data]) {
    if (data == null) return message;
    if (data is Map) {
      final kv = data.entries
          .map((e) => '${e.key}=${_stringify(e.value)}')
          .join(' ');
      return '$message | $kv';
    }
    return '$message | ${_stringify(data)}';
  }

  /// Stringifies a log value, truncating long strings so a single log line
  /// stays bounded and greppable.
  static String _stringify(dynamic value) {
    if (value == null) return 'null';
    final s = value.toString();
    if (s.length <= 200) return s;
    return '${s.substring(0, 200)}…(${s.length} chars)';
  }
}
