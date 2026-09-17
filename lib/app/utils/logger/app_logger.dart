import 'package:logger/logger.dart';

import '../../../config/app_config.dart';

class AppLogger {
  // Log-level guide (pick the lowest level that fits):
  // - debug: hot-loop detail (per-request/response, retries, timers, frames).
  //   This is the ONLY level allowed in loops or per-request paths.
  // - info: one-off lifecycle milestones (login, init done, navigation).
  // - warning: recoverable trouble (transient refresh failure, fallback).
  // - error: needs a human (auth-class failures, unhandled exceptions).
  // Hot-loop rule: per-request logging (e.g. BaseProvider request/response
  // modifiers, retry attempts) stays at debug — never info/warning — so
  // production (level=warning) is not spammed. Correlation: pass runId
  // (one operation) and/or userId (one user) to stitch related lines.
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

  static void debug(
    String message, [
    dynamic data,
    String? runId,
    String? userId,
  ]) => _logger.d(_fmt(message, data, runId, userId));
  static void info(
    String message, [
    dynamic data,
    String? runId,
    String? userId,
  ]) => _logger.i(_fmt(message, data, runId, userId));
  static void warning(
    String message, [
    dynamic data,
    String? runId,
    String? userId,
  ]) => _logger.w(_fmt(message, data, runId, userId));
  static void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    String? runId,
    String? userId,
  ]) => _logger.e(
    _fmt(message, error, runId, userId),
    error: error,
    stackTrace: stackTrace,
  );

  static void logRequest(dynamic request, [String? runId, String? userId]) =>
      _logger.d(_fmt('API Request', request, runId, userId));
  static void logResponse(dynamic response, [String? runId, String? userId]) =>
      _logger.d(_fmt('API Response', response, runId, userId));

  static String _fmt(
    String message, [
    dynamic data,
    String? runId,
    String? userId,
  ]) {
    final ctx = [
      if (runId != null && runId.isNotEmpty) 'run=$runId',
      if (userId != null && userId.isNotEmpty) 'user=$userId',
    ].join(' ');
    String withCtx(String s) => ctx.isEmpty ? s : '$s | $ctx';
    if (data == null) return withCtx(message);
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
