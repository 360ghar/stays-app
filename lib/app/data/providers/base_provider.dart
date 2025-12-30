import 'package:get/get.dart';

import 'dart:async';

import '../../../config/app_config.dart';
import '../../utils/logger/app_logger.dart';
import '../services/storage_service.dart';
import '../../utils/services/token_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/exceptions/app_exceptions.dart';
import '../../utils/services/error_service.dart';

/// Retry configuration for transient failures
const int _maxRetries = 3;
const Duration _initialRetryDelay = Duration(milliseconds: 500);

/// Status codes that are safe to retry
const Set<int> _retryableStatusCodes = {408, 429, 500, 502, 503, 504};

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
    httpClient.baseUrl = AppConfig.I.apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 30);

    httpClient.addRequestModifier<Object?>((request) async {
      // Prefer Supabase session token; fallback to secure storage (async)
      final supabaseToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
      final legacyToken = await (await _getStorage()).getAccessToken();
      final token = supabaseToken ?? legacyToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      } else {
        request.headers.remove('Authorization');
      }
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';
      // Lightweight request timing for performance monitoring
      request.headers['x-start-ms'] = DateTime.now().millisecondsSinceEpoch
          .toString();
      AppLogger.logRequest({
        'method': request.method,
        'url': request.url.toString(),
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
        'url': request.url.toString(),
        if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      });
      // Passive handler: authenticator below will retry.
      return response;
    });
    // Retry once on 401 by attempting token refresh via Supabase.
    httpClient.maxAuthRetries = 1;
    httpClient.addAuthenticator<Object?>((request) async {
      // Skip auth endpoints to avoid loops
      if (_isAuthEndpoint(request.url)) return request;
      AppLogger.info('Authenticator triggered for ${request.url}');
      final client = Supabase.instance.client;
      try {
        final session = client.auth.currentSession;
        if (session == null) {
          // Try refresh with stored refresh token if available
          final refreshToken = await (await _getStorage()).getRefreshToken();
          if (refreshToken == null || refreshToken.isEmpty) {
            throw ApiException(
              message: 'No session to refresh',
              statusCode: 401,
            );
          }
          // Supabase Flutter SDK refreshes based on current session; signInWithIdToken
          // not applicable here. Attempt to set session from refresh token.
          final res = await client.auth.refreshSession();
          if (res.session == null) {
            throw ApiException(message: 'Unable to refresh', statusCode: 401);
          }
        } else {
          final res = await client.auth.refreshSession();
          if (res.session == null) {
            throw ApiException(message: 'Unable to refresh', statusCode: 401);
          }
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
          AppLogger.info('Auth token refreshed; retrying ${request.url}');
          return request;
        }
        throw ApiException(
          message: 'Missing access token after refresh',
          statusCode: 401,
        );
      } catch (e, s) {
        AppLogger.error('Token refresh failed', e, s);
        final storage = await _getStorage();
        await storage.clearTokens();
        await storage.clearUserData();
        if (Get.currentRoute != '/login') {
          unawaited(Get.offAllNamed('/login'));
        }
        return request; // Let original request fail; no infinite retry
      }
    });
    super.onInit();
  }

  T handleResponse<T>(Response response, T Function(dynamic) parser) {
    final int statusCode = response.statusCode ?? 500;

    // Only log response body in dev to prevent leaking sensitive data
    if (AppConfig.isDev) {
      AppLogger.info(
        'API Response [${response.request?.url}] - Status: $statusCode, Body: ${response.bodyString}',
      );
    } else {
      AppLogger.info(
        'API Response [${response.request?.url}] - Status: $statusCode',
      );
    }

    if (response.isOk) {
      // SUCCESS CASE (Status codes 200-299)
      if (response.body == null) {
        // This can happen on successful logout or delete requests
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
    return url.path.contains('/auth/') ||
        url.path.contains('/login') ||
        url.path.contains('/register');
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
      () => get<T>(
        url,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
      ),
    );
  }

  /// Execute a POST request with automatic retry for transient failures
  Future<Response<T>> postWithRetry<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) async {
    return _executeWithRetry(
      () => post<T>(
        url,
        body,
        contentType: contentType,
        headers: headers,
        query: query,
        decoder: decoder,
      ),
    );
  }

  /// Internal retry logic with exponential backoff
  Future<Response<T>> _executeWithRetry<T>(
    Future<Response<T>> Function() operation,
  ) async {
    int attempt = 0;
    Duration delay = _initialRetryDelay;

    while (true) {
      try {
        final response = await operation();

        // Check if response is retryable
        final statusCode = response.statusCode ?? 0;
        if (_retryableStatusCodes.contains(statusCode) &&
            attempt < _maxRetries) {
          attempt++;
          AppLogger.warning(
            'Request failed with status $statusCode. Retry attempt $attempt/$_maxRetries after ${delay.inMilliseconds}ms',
          );
          await Future<void>.delayed(delay);
          delay *= 2; // Exponential backoff
          continue;
        }

        return response;
      } catch (e) {
        // Retry on network errors (timeout, connection refused, etc.)
        if (_isRetryableError(e) && attempt < _maxRetries) {
          attempt++;
          AppLogger.warning(
            'Request failed with error: $e. Retry attempt $attempt/$_maxRetries after ${delay.inMilliseconds}ms',
          );
          await Future<void>.delayed(delay);
          delay *= 2;
          continue;
        }
        rethrow;
      }
    }
  }

  /// Check if an error is retryable (network-related)
  bool _isRetryableError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('timeout') ||
        errorStr.contains('connection') ||
        errorStr.contains('socket') ||
        errorStr.contains('network');
  }
}
