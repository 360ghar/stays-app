import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
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
/// dio internal types (kept web-safe — no dart:io imports).
@visibleForTesting
TransportFailureKind classifyTransportFailure(Object error) {
  if (error is TimeoutException) {
    return TransportFailureKind.possiblySent;
  }
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TransportFailureKind.possiblySent;
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        break; // Fall through to message markers below.
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.cancel:
        return TransportFailureKind.possiblySent;
    }
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

/// Minimal HTTP response shape. Replaces the GetConnect `Response` type so
/// providers stay transport-agnostic.
class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    this.statusMessage,
    this.data,
    this.bodyString = '',
    this.headers = const <String, String>{},
    this.uri,
  });

  final int statusCode;
  final String? statusMessage;
  final dynamic data;
  final String bodyString;
  final Map<String, String> headers;
  final Uri? uri;

  bool get isOk => statusCode >= 200 && statusCode < 300;

  /// Safely coerce the body into a JSON map. Returns empty map if missing
  /// or not decodable.
  Map<String, dynamic> bodyAsMap() {
    final b = data;
    if (b is Map) return Map<String, dynamic>.from(b);
    if (bodyString.isNotEmpty) {
      try {
        final decoded = jsonDecode(bodyString);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  /// Retry delay hint from the `Retry-After` response header (seconds),
  /// capped to a sane maximum.
  Duration? get retryAfter {
    final raw = headers['retry-after'];
    final seconds = int.tryParse(raw?.trim() ?? '');
    if (seconds == null || seconds <= 0) return null;
    return Duration(seconds: seconds.clamp(1, _maxRetryAfterDelay.inSeconds));
  }
}

abstract class BaseProvider {
  BaseProvider({
    String? baseUrl,
    Duration timeout = const Duration(seconds: 30),
    ConnectivityService? connectivity,
    TokenService? tokens,
    StorageService? storage,
    PerformanceMonitor? performance,
    ErrorService? errorService,
    bool authHeader = true,
  }) : _baseUrlOverride = baseUrl ?? '',
       _timeout = timeout,
       _connectivityOverride = connectivity,
       _tokensOverride = tokens,
       _storageOverride = storage,
       _performanceOverride = performance,
       _errorService = errorService ?? ErrorService(),
       _authHeader = authHeader;

  final String _baseUrlOverride;
  final Duration _timeout;
  final ConnectivityService? _connectivityOverride;
  final TokenService? _tokensOverride;
  final StorageService? _storageOverride;
  final PerformanceMonitor? _performanceOverride;
  final ErrorService _errorService;

  /// False for third-party hosts (e.g. Google Places): never send our
  /// backend bearer token to another authority.
  final bool _authHeader;

  // Service singletons are the defaults so every provider gets full
  // behavior (connectivity guard, token sync, metrics) without explicit
  // wiring; tests can still inject fakes via the constructor.
  ConnectivityService get _connectivity =>
      _connectivityOverride ?? ConnectivityService();
  TokenService get _tokens => _tokensOverride ?? TokenService.shared();
  StorageService get _storage => _storageOverride ?? StorageService();
  PerformanceMonitor get _performance =>
      _performanceOverride ?? PerformanceMonitor();

  Dio? _dio;

  Dio get _client {
    final existing = _dio;
    if (existing != null) return existing;
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl.isEmpty ? AppConfig.I.api.apiBaseUrl : _baseUrl,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        // Every HTTP status returns normally; transport errors throw.
        // Retry/auth logic below inspects statuses itself.
        validateStatus: (_) => true,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Always use the active Supabase session as the source of truth.
          // Skipped for third-party hosts (see [authHeader]).
          if (_authHeader) {
            final supabaseToken =
                Supabase.instance.client.auth.currentSession?.accessToken;
            final token = supabaseToken;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            } else {
              options.headers.remove('Authorization');
            }
          } else {
            options.headers.remove('Authorization');
          }
          options.headers['Accept'] = 'application/json';
          // Lightweight request timing for performance monitoring
          options.extra['start-ms'] =
              DateTime.now().millisecondsSinceEpoch.toString();
          // Never log headers: Authorization bearer tokens must stay out of
          // logs. URLs are redacted (query + fragment stripped) — query
          // params may carry tokens.
          AppLogger.logRequest({
            'method': options.method,
            'url': _redactUri(options.uri).toString(),
          });
          handler.next(options);
        },
        onResponse: (response, handler) {
          final startHeader = response.requestOptions.extra['start-ms'];
          int? elapsedMs;
          if (startHeader != null) {
            final startMs = int.tryParse(startHeader.toString());
            if (startMs != null) {
              elapsedMs = DateTime.now().millisecondsSinceEpoch - startMs;
            }
          }
          AppLogger.logResponse({
            'status': response.statusCode,
            'url': _redactUri(response.requestOptions.uri).toString(),
            'elapsed_ms': ?elapsedMs,
          });
          handler.next(response);
        },
      ),
    );
    return _dio = dio;
  }

  String get _baseUrl => _baseUrlOverride.isEmpty
      ? AppConfig.I.api.apiBaseUrl
      : _baseUrlOverride;

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

  T handleResponse<T>(ApiResponse response, T Function(dynamic) parser) {
    final int statusCode = response.statusCode;
    // Redact query/fragment (may carry tokens); body only logged in dev.
    final redactedUrl = response.uri == null
        ? 'unknown'
        : _redactUri(response.uri!).toString();

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
      if (_isEmptyBody(response.data)) {
        // This can happen on successful logout, 204 No Content responses,
        // or 200 OK with an empty body. Treat all three as "no payload".
        return parser(null);
      }
      return parser(response.data);
    } else {
      // Delegate to central error service
      throw _errorService.toApiException(response);
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
  Future<ApiResponse> getWithRetry(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    return _executeWithRetry(
      () => _request('GET', url, headers: headers, query: query),
    );
  }

  /// Execute a POST request with automatic retry for transient failures.
  ///
  /// Non-idempotent methods are retried ONLY when the request was never
  /// delivered to the server; an `Idempotency-Key` header is added so the
  /// backend can dedupe repeated deliveries.
  Future<ApiResponse> postWithRetry(
    String? url,
    dynamic body, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final effectiveHeaders = _withIdempotencyKey(headers, 'POST');
    return _executeWithRetry(
      () => _request('POST', url, data: body, headers: effectiveHeaders, query: query),
      method: 'POST',
    );
  }

  /// Execute a PUT request with automatic retry for transient failures.
  Future<ApiResponse> putWithRetry(
    String url,
    dynamic body, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final effectiveHeaders = _withIdempotencyKey(headers, 'PUT');
    return _executeWithRetry(
      () => _request('PUT', url, data: body, headers: effectiveHeaders, query: query),
      method: 'PUT',
    );
  }

  /// Execute a DELETE request with automatic retry for transient failures.
  Future<ApiResponse> deleteWithRetry(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final effectiveHeaders = _withIdempotencyKey(headers, 'DELETE');
    return _executeWithRetry(
      () => _request('DELETE', url, headers: effectiveHeaders, query: query),
      method: 'DELETE',
    );
  }

  Future<ApiResponse> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) => getWithRetry(url, headers: headers, query: query);

  Future<ApiResponse> post(
    String? url,
    dynamic body, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) => postWithRetry(url, body, headers: headers, query: query);

  Future<ApiResponse> put(
    String url,
    dynamic body, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) => putWithRetry(url, body, headers: headers, query: query);

  Future<ApiResponse> delete(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) => deleteWithRetry(url, headers: headers, query: query);

  Future<ApiResponse> _request(
    String method,
    String? url, {
    dynamic data,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _client.request<dynamic>(
        url ?? '',
        data: data,
        queryParameters: query,
        options: Options(method: method, headers: headers),
      );
      return _toApiResponse(response);
    } on DioException catch (e) {
      final response = e.response;
      if (response != null) {
        return _toApiResponse(response);
      }
      rethrow;
    }
  }

  ApiResponse _toApiResponse(Response<dynamic> response) {
    final data = response.data;
    final flatHeaders = <String, String>{};
    response.headers.forEach((name, values) {
      if (values.isNotEmpty) flatHeaders[name.toLowerCase()] = values.first;
    });
    return ApiResponse(
      statusCode: response.statusCode ?? 0,
      statusMessage: response.statusMessage,
      data: data,
      bodyString: data is String ? data : '',
      headers: flatHeaders,
      uri: response.requestOptions.uri,
    );
  }

  /// Internal retry logic with exponential backoff.
  ///
  /// [method] drives the retry policy: only idempotent methods are retried on
  /// server responses, and non-idempotent methods are retried only when the
  /// request was provably never delivered to the server.
  Future<ApiResponse> _executeWithRetry(
    Future<ApiResponse> Function() operation, {
    String method = 'GET',
  }) async {
    int attempt = 0;
    Duration delay = _initialRetryDelay;
    final stopwatch = Stopwatch()..start();
    var authRetried = false;

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
          var response = await operation();

          // Retry once on 401 by attempting token refresh via Supabase.
          if (response.statusCode == 401 &&
              !authRetried &&
              !_isAuthEndpoint(response.uri ?? Uri())) {
            authRetried = true;
            AppLogger.debug(
              'Authenticator triggered for ${_redactUri(response.uri ?? Uri())}',
            );
            if (await _tryRefreshSession(response)) {
              response = await operation();
            }
          }

          // Server responded: retry only idempotent methods on transient codes.
          final statusCode = response.statusCode;
          try {
            _performance.recordCount('provider.$method.$statusCode');
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
            AppLogger.warning(
              'Request failed with status $statusCode. Retry attempt $attempt/${_maxRetries - 1} after ${delay.inMilliseconds}ms',
            );
            await Future<void>.delayed(_nextDelay(delay, response.retryAfter));
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
        _performance.recordElapsed(
          'provider.$method',
          stopwatch.elapsedMilliseconds,
        );
        _performance.recordCount('provider.$method');
      } catch (_) {
        // Never fail the request for metrics.
      }
    }
  }

  /// Attempts a Supabase session refresh after a 401 and keeps
  /// [TokenService]/storage in sync. Returns true when the caller should
  /// retry the request with the fresh session token.
  Future<bool> _tryRefreshSession(ApiResponse response) async {
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
          await _tokens.storeTokens(
            accessToken: newToken,
            refreshToken: newRefresh,
          );
        } catch (_) {
          // Fallback to direct storage if TokenService not available
          await _storage.saveTokens(
            accessToken: newToken,
            refreshToken: newRefresh,
          );
        }
        AppLogger.debug(
          'Auth token refreshed; retrying ${_redactUri(response.uri ?? Uri())}',
        );
        return true;
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
        await _storage.clearTokens();
        await _storage.clearUserData();
      } else {
        AppLogger.warning(
          'Session refresh failed transiently (session kept): $e',
        );
      }
      return false; // Let the original request fail; no infinite retry
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
    final service = _connectivity;
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
