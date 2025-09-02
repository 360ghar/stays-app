import 'package:logger/logger.dart';

import '../../../config/app_config.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: _getLogLevel(),
  );

  static Level _getLogLevel() {
    if (AppConfig.isProduction) return Level.warning;
    if (AppConfig.isStaging) return Level.info;
    return Level.trace;
  }

  static void debug(String message, [dynamic data]) => _logger.d(_fmt(message, data));
  static void info(String message, [dynamic data]) => _logger.i(_fmt(message, data));
  static void warning(String message, [dynamic data]) => _logger.w(_fmt(message, data));
  static void error(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(_fmt(message, error), stackTrace: stackTrace);

  static void logRequest(dynamic request) => _logger.d(_fmt('API Request', request));
  static void logResponse(dynamic response) => _logger.d(_fmt('API Response', response));

  static String _fmt(String message, [dynamic data]) =>
      data == null ? message : '$message | ${data.toString()}';
}
