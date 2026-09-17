import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../utils/logger/app_logger.dart';
import '../../utils/performance/performance_monitor.dart';
import '../../utils/exceptions/app_exceptions.dart';
import '../../utils/exceptions/network_exceptions.dart';
import '../../utils/services/connectivity_service.dart';
import '../../utils/services/error_service.dart';
import '../../utils/services/token_service.dart';
import '../services/storage_service.dart';

/// Retry configuration for transient failures.
const int _maxRetries = 3; // 1 initial attempt + 2 retries
const Duration _initialRetryDelay = Duration(milliseconds: 500);
const Duration _maxRetryDelay = Duration(seconds: 8);
const Duration _maxRetryAfterDelay = Duration(seconds: 10);

/// Status codes that are safe to retry for idempotent requests.
const Set<int> _retryableStatusCodes = {408, 429, 500, 502, 503, 504};

/// HTTP methods that are safe to retry after the server may have processed
/// the request (no side effects or idempotent by contract).
bool _isIdempotentMethod(String method) {
  switch (method.toUpperCase()) {
    case 'GET':
    case 'HEAD':
    case 'OPTIONS':
      return true;
    default:
      return false;
  }
}

/// Decides whether a failed request may be retried.
///
/// Rules:
/// - Never retry past the configured attempt budget.
/// - A request that was never delivered to the server can always be retried.
/// - A request whose delivery is uncertain (timeout, reset) is retried only
///   when the method is idempotent.
/// - A server response (any status) is retried only for idempotent methods
///   and only for statuses known to be transient (408/429/5xx).
@visibleForTesting
bool shouldRetryRequest({
  required String method,
  required int attempt,
  required TransportFailureKind transportFailure,
  int? statusCode,
}) {
  if (attempt >= _maxRetries - 1) return false;
  if (transportFailure == TransportFailureKind.neverSent) return true;
  if (transportFailure == TransportFailureKind.possiblySent) {
    return _isIdempotentMethod(method);
  }
  // Server responded with a status code.
  if (!_isIdempotentMethod(method)) return false;
  return _retryableStatusCodes.contains(statusCode);
}

/// Classifies a thrown error into a [TransportFailureKind] without naming
/// get/dio internal types (kept web-safe — no dart:io imports).
@visibleForTesting
TransportFailureKind classifyTransportFailure(Object error) {
  if (error is TimeoutException) {
    return TransportFailureKind.possiblySent;
  }
  final message = error.toString().toLowerCase();
  const neverSentMarkers = <String>[
    'connection refused',
    'failed host lookup',
    'unable to resolve host',
    'host lookup failed',
    'network is unreachable',
    'connection failed',
    'connection actively refused',
  ];
  for (final marker in neverSentMarkers) {
    if (message.contains(marker)) {
      return TransportFailureKind.neverSent;
    }
  }
  const possiblySentMarkers = <String>[
    'timed out',
    'timeout',
    'connection reset',
    'socket',
    'connection closed',
  ];
  for (final marker in possiblySentMarkers) {
    if (message.contains(marker)) {
      return TransportFailureKind.possiblySent;
    }
  }
  // A thrown error means no response was received; assume the worst case.
  return TransportFailureKind.possiblySent;
}

abstract class BaseProvider extends GetConnect {
  StorageService? _storage;

  Future<StorageService> _getStorage() async {
    if (_storage != null) return _storage!;
    await StorageService.ready;
    _storage = Get.find<StorageService>();
    return _storage!;
  }

  @override
  void onInit() {
    httpClient.baseUrl = AppConfig.I.api.apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 30);

    httpClient.addRequestModifier<Object?>((request) async {
      // Always use the active Supabase session as the source of truth.
      final supabaseToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
      final token = supabaseToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      } else {
        request.headers.remove('Authorization');
      }
      // Do not force Content-Type here: GetConnect sets application/json for
      // Map bodies and multipart/form-data (+ boundary) for FormData uploads.
      request.headers['Accept'] = 'application/json';
      // Lightweight request timing for performance monitoring
      request.headers['x-start-ms'] = DateTime.now().millisecondsSinceEpoch
          .toString();
      // Never log headers: Authorization bearer tokens must stay out of logs.
      // URLs are redacted (query + fragment stripped) like
      // DeepLinkService._redact — query params may carry tokens.
      AppLogger.logRequest({
        'method': request.method,
        'url': _redactUri(request.url).toString(),
      });
      return request;
    });

    httpClient.addResponseModifier<Object?>((request, response) async {
      final startHeader = request.headers['x-start-ms'];
      int? elapsedMs;
      if (startHeader != null) {
        final startMs = int.tryParse(startHeader);
        if (startMs != null) {
          elapsedMs = DateTime.now().millisecondsSinceEpoch - startMs;
        }
      }
      AppLogger.logResponse({
        'status': response.statusCode,
        'url': _redactUri(request.url).toString(),
        'elapsed_ms': ?elapsedMs,
      });
      // Passive handler: authenticator below will retry.
      return response;
    });
    // Retry once on 401 by attempting token refresh via Supabase.
    httpClient.maxAuthRetries = 1;
    httpClient.addAuthenticator<Object?>((request) async {
      // Skip auth endpoints to avoid loops
      if (_isAuthEndpoint(request.url)) return request;
      AppLogger.debug('Authenticator triggered for ${_redactUri(request.url)}');
      final client = Supabase.instance.client;
      try {
        final session = client.auth.currentSession;
        if (session == null) {
          throw ApiException(message: 'No session to refresh', statusCode: 401);
        }

        final res = await client.auth.refreshSession();
        if (res.session == null) {
          throw ApiException(message: 'Unable to refresh', statusCode: 401);
        }
        final newToken = client.auth.currentSession?.accessToken;
        final newRefresh = client.auth.currentSession?.refreshToken;
        if (newToken != null) {
          // Keep TokenService + storage in sync via service layer
          try {
            final tokenService = Get.find<TokenService>();
            await tokenService.storeTokens(
              accessToken: newToken,
              refreshToken: newRefresh,
            );
          } catch (_) {
            // Fallback to direct storage if TokenService not available
            final storage = await _getStorage();
            await storage.saveTokens(
              accessToken: newToken,
              refreshToken: newRefresh,
            );
          }
          request.headers['Authorization'] = 'Bearer $newToken';
          AppLogger.debug(
            'Auth token refreshed; retrying ${_redactUri(request.url)}',
          );
          return request;
        }
        throw ApiException(
          message: 'Missing access token after refresh',
          statusCode: 401,
        );
      } catch (e, s) {
        AppLogger.error('Token refresh failed', e, s);
        if (_isAuthClassFailure(e)) {
          // Only auth-class failures (expired/invalid/revoked refresh token)
          // invalidate the local session. Transient network errors during
          // refresh must NOT log the user out or wipe local data.
          final storage = await _getStorage();
          await storage.clearTokens();
          await storage.clearUserData();
        } else {
          AppLogger.warning(
            'Session refresh failed transiently (session kept): $e',
          );
        }
        return request; // Let the original request fail; no infinite retry
      }
    });
    super.onInit();
  }

  /// True when a refresh failure means the session itself is unusable
  /// (as opposed to a transient network problem).
  bool _isAuthClassFailure(Object error) {
    if (error is ApiException) {
      return error.statusCode == 401 || error.statusCode == 403;
    }
    final message = error.toString().toLowerCase();
    return message.contains('invalid_grant') ||
        message.contains('refresh token not found') ||
        message.contains('invalid refresh token') ||
        message.contains('token has expired') ||
        message.contains('invalid jwt') ||
        message.contains('expired jwt');
  }

  T handleResponse<T>(Response response, T Function(dynamic) parser) {
    final int statusCode = response.statusCode ?? 500;
    // Redact query/fragment (may carry tokens); body only logged in dev.
    final redactedUrl = response.request?.url == null
        ? 'unknown'
        : _redactUri(response.request!.url).toString();

    // Only log response body in dev to prevent leaking sensitive data
    if (AppConfig.isDev) {
      AppLogger.info(
        'API Response [$redactedUrl] - Status: $statusCode, Body: ${response.bodyString}',
      );
    } else {
      AppLogger.info('API Response [$redactedUrl] - Status: $statusCode');
    }

    if (response.isOk) {
      // SUCCESS CASE (Status codes 200-299)
      if (_isEmptyBody(response.body)) {
        // This can happen on successful logout, 204 No Content responses,
        // or 200 OK with an empty body. Treat all three as "no payload".
        return parser(null);
      }
      return parser(response.body);
    } else {
      // Delegate to central error service
      throw ErrorService.I.toApiException(response);
    }
  }

  /// Check if the current request is for auth endpoints
  bool _isAuthEndpoint(Uri url) {
    return url.path.contains('/auth') ||
        url.path.contains('/login') ||
        url.path.contains('/register');
  }

  /// Strips query and fragment before logging — mirrors
  /// DeepLinkService._redact. Query params may carry tokens or PII that
  /// should never be written to logs. Headers (esp. Authorization) are
  /// never logged.
  static Uri _redactUri(Uri uri) => uri.replace(query: '', fragment: '');

  /// True when [body] is missing or an empty string. A 200 OK with a blank
  /// payload (common when an endpoint transitions from 204 to 200) should be
  /// treated the same as 204.
  bool _isEmptyBody(dynamic body) {
    if (body == null) return true;
    if (body is String && body.isEmpty) return true;
    if (body is List && body.isEmpty) return true;
    if (body is Map && body.isEmpty) return true;
    return false;
  }

  /// Execute a GET request with automatic retry for transient failures
  Future<Response<T>> getWithRetry<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) async {
    return _executeWithRetry(
      () => super.get<T>(
        url,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
      ),
    );
  }

  /// Execute a POST request with automatic retry for transient failures.
  ///
  /// Non-idempotent methods are retried ONLY when the request was never
  /// delivered to the server; an `Idempotency-Key` header is added so the
  /// backend can dedupe repeated deliveries.
  Future<Response<T>> postWithRetry<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    final effectiveHeaders = _withIdempotencyKey(headers, 'POST');
    return _executeWithRetry(
      () => super.post<T>(
        url,
        body,
        contentType: contentType,
        headers: effectiveHeaders,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
      method: 'POST',
    );
  }

  /// Execute a PUT request with automatic retry for transient failures.
  Future<Response<T>> putWithRetry<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    final effectiveHeaders = _withIdempotencyKey(headers, 'PUT');
    return _executeWithRetry(
      () => super.put<T>(
        url,
        body,
        contentType: contentType,
        headers: effectiveHeaders,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
      method: 'PUT',
    );
  }

  /// Execute a DELETE request with automatic retry for transient failures.
  Future<Response<T>> deleteWithRetry<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) async {
    final effectiveHeaders = _withIdempotencyKey(headers, 'DELETE');
    return _executeWithRetry(
      () => super.delete<T>(
        url,
        headers: effectiveHeaders,
        contentType: contentType,
        query: query,
        decoder: decoder,
      ),
      method: 'DELETE',
    );
  }

  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) => getWithRetry<T>(
    url,
    headers: headers,
    contentType: contentType,
    query: query,
    decoder: decoder,
  );

  @override
  Future<Response<T>> post<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) => postWithRetry<T>(
    url,
    body,
    contentType: contentType,
    headers: headers,
    query: query,
    decoder: decoder,
    uploadProgress: uploadProgress,
  );

  @override
  Future<Response<T>> put<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) => putWithRetry<T>(
    url,
    body,
    contentType: contentType,
    headers: headers,
    query: query,
    decoder: decoder,
    uploadProgress: uploadProgress,
  );

  @override
  Future<Response<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) => deleteWithRetry<T>(
    url,
    headers: headers,
    contentType: contentType,
    query: query,
    decoder: decoder,
  );

  /// Internal retry logic with exponential backoff.
  ///
  /// [method] drives the retry policy: only idempotent methods are retried on
  /// server responses, and non-idempotent methods are retried only when the
  /// request was provably never delivered to the server.
  Future<Response<T>> _executeWithRetry<T>(
    Future<Response<T>> Function() operation, {
    String method = 'GET',
  }) async {
    int attempt = 0;
    Duration delay = _initialRetryDelay;
    final stopwatch = Stopwatch()..start();

    try {
      while (true) {
        if (!await _hasNetworkConnection()) {
          throw ApiException(
            message:
                'No internet connection. Please check your network and try again.',
            statusCode: 0,
          );
        }
        try {
          final response = await operation();

          // Server responded: retry only idempotent methods on transient codes.
          final statusCode = response.statusCode ?? 0;
          try {
            if (Get.isRegistered<PerformanceMonitor>()) {
              PerformanceMonitor.I.recordCount('provider.$method.$statusCode');
            }
          } catch (_) {
            // Never fail the request for metrics.
          }
          if (statusCode != 0 &&
              shouldRetryRequest(
                method: method,
                statusCode: statusCode,
                attempt: attempt,
                transportFailure: TransportFailureKind.none,
              )) {
            attempt++;
            final retryAfter = _retryAfterSeconds(response);
            AppLogger.warning(
              'Request failed with status $statusCode. Retry attempt $attempt/${_maxRetries - 1} after ${delay.inMilliseconds}ms',
            );
            await Future<void>.delayed(_nextDelay(delay, retryAfter));
            delay = _nextBackoff(delay);
            continue;
          }

          return response;
        } catch (e) {
          final failure = classifyTransportFailure(e);
          if (failure != TransportFailureKind.none &&
              shouldRetryRequest(
                method: method,
                attempt: attempt,
                transportFailure: failure,
              )) {
            attempt++;
            AppLogger.warning(
              'Request failed with error: $e. Retry attempt $attempt/${_maxRetries - 1} after ${delay.inMilliseconds}ms',
            );
            await Future<void>.delayed(delay);
            delay = _nextBackoff(delay);
            continue;
          }
          if (failure != TransportFailureKind.none) {
            AppLogger.warning(
              'Network request failed after $attempt retries: $e',
            );
            throw ApiException(
              message: _networkErrorMessage(e),
              statusCode: 408,
              transportFailure: failure,
            );
          }
          rethrow;
        }
      }
    } finally {
      stopwatch.stop();
      try {
        if (Get.isRegistered<PerformanceMonitor>()) {
          PerformanceMonitor.I.recordElapsed(
            'provider.$method',
            stopwatch.elapsedMilliseconds,
          );
          PerformanceMonitor.I.recordCount('provider.$method');
        }
      } catch (_) {
        // PerformanceMonitor absent (e.g. unit tests without bindings):
        // never fail the request for metrics.
      }
    }
  }

  /// Adds a stable `Idempotency-Key` header to non-idempotent requests so the
  /// backend can dedupe retried deliveries. Caller-supplied keys win.
  Map<String, String>? _withIdempotencyKey(
    Map<String, String>? headers,
    String method,
  ) {
    if (_isIdempotentMethod(method)) return headers;
    final merged = {...?headers};
    merged.putIfAbsent('Idempotency-Key', _generateIdempotencyKey);
    return merged;
  }

  String _generateIdempotencyKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Parses the `Retry-After` header (seconds) with a sane cap.
  Duration? _retryAfterSeconds(Response response) {
    final raw =
        response.headers?['retry-after'] ?? response.headers?['Retry-After'];
    final seconds = int.tryParse(raw?.trim() ?? '');
    if (seconds == null || seconds <= 0) return null;
    return Duration(seconds: seconds.clamp(1, _maxRetryAfterDelay.inSeconds));
  }

  /// Backoff delay with ±20% jitter, overridden by `Retry-After` when present.
  Duration _nextDelay(Duration base, Duration? retryAfter) {
    if (retryAfter != null) return retryAfter;
    final jitter = 0.8 + (Random().nextDouble() * 0.4);
    return Duration(milliseconds: (base.inMilliseconds * jitter).round());
  }

  Duration _nextBackoff(Duration delay) {
    final doubled = delay * 2;
    return doubled > _maxRetryDelay ? _maxRetryDelay : doubled;
  }

  Future<bool> _hasNetworkConnection() async {
    if (!Get.isRegistered<ConnectivityService>()) {
      return true;
    }
    final service = Get.find<ConnectivityService>();
    if (service.isCurrentlyOnline) {
      return true;
    }
    return service.checkConnection();
  }

  String _networkErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (errorStr.contains('socket') ||
        errorStr.contains('connection') ||
        errorStr.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    return 'Network request failed. Please try again.';
  }
}
