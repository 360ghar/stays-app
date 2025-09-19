import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class DebugLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final logMessage = tag != null ? '[$tag] $message' : message;
      _logger.d(logMessage);
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final logMessage = tag != null ? '[$tag] $message' : message;
      _logger.i(logMessage);
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      final logMessage = tag != null ? '[$tag] $message' : message;
      _logger.w(logMessage);
    }
  }

  static void error(String message, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }

  static void verbose(String message, {String? tag}) {
    if (kDebugMode) {
      final logMessage = tag != null ? '[$tag] $message' : message;
      _logger.t(logMessage);
    }
  }

  // API specific logging
  static void api(String message) {
    log(message, tag: 'API');
  }

  // Auth specific logging
  static void auth(String message) {
    log(message, tag: 'AUTH');
  }

  // Startup specific logging
  static void startup(String message) {
    info(message, tag: 'STARTUP');
  }

  // Success logging
  static void success(String message) {
    info('✅ $message', tag: 'SUCCESS');
  }

  // JWT Token logging
  static void logJWTToken(
    String token, {
    DateTime? expiresAt,
    String? userId,
    String? userEmail,
  }) {
    if (kDebugMode) {
      final tokenPreview =
          token.length > 20 ? '${token.substring(0, 20)}...' : token;
      var message = 'JWT Token: $tokenPreview';

      if (expiresAt != null) {
        message += '\nExpires: $expiresAt';
      }
      if (userId != null) {
        message += '\nUser ID: $userId';
      }
      if (userEmail != null) {
        message += '\nEmail: $userEmail';
      }

      log(message, tag: 'JWT');
    }
  }

  // API Request logging
  static void logAPIRequest(
    String method,
    String url, {
    dynamic body,
    Map<String, dynamic>? headers,
  }) {
    if (kDebugMode) {
      var message = '$method $url';
      if (headers != null) {
        message += '\nHeaders: $headers';
      }
      if (body != null) {
        message += '\nBody: $body';
      }
      log(message, tag: 'API Request');
    }
  }

  // API Response logging
  static void logAPIResponse(int statusCode, String url, {dynamic body}) {
    if (kDebugMode) {
      var message = 'Status $statusCode for $url';
      if (body != null) {
        final bodyStr = body.toString();
        if (bodyStr.length > 500) {
          message += '\nBody: ${bodyStr.substring(0, 500)}...';
        } else {
          message += '\nBody: $bodyStr';
        }
      }
      log(message, tag: 'API Response');
    }
  }
}
