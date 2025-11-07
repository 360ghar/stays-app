import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../utils/logger/app_logger.dart';
import '../services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/exceptions/app_exceptions.dart';
import '../../utils/services/error_service.dart';

abstract class BaseProvider extends GetConnect {
  final StorageService _storage = Get.find<StorageService>();

  @override
  void onInit() {
    httpClient.baseUrl = AppConfig.I.apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 30);

    httpClient.addRequestModifier<Object?>((request) async {
      // Prefer Supabase session token; fallback to secure storage (async)
      final supabaseToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
      final legacyToken = await _storage.getAccessToken();
      final token = supabaseToken ?? legacyToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      } else {
        request.headers.remove('Authorization');
      }
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';
      // Lightweight request timing for performance monitoring
      request.headers['x-start-ms'] =
          DateTime.now().millisecondsSinceEpoch.toString();
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
          final refreshToken = await _storage.getRefreshToken();
          if (refreshToken == null || refreshToken.isEmpty) {
            throw ApiException(message: 'No session to refresh', statusCode: 401);
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
          await _storage.saveTokens(accessToken: newToken, refreshToken: newRefresh);
          request.headers['Authorization'] = 'Bearer $newToken';
          AppLogger.info('Auth token refreshed; retrying ${request.url}');
          return request;
        }
        throw ApiException(message: 'Missing access token after refresh', statusCode: 401);
      } catch (e, s) {
        AppLogger.error('Token refresh failed', e, s);
        await _storage.clearTokens();
        await _storage.clearUserData();
        if (Get.currentRoute != '/login') {
          Get.offAllNamed('/login');
        }
        return request; // Let original request fail; no infinite retry
      }
    });
    super.onInit();
  }

  T handleResponse<T>(Response response, T Function(dynamic) parser) {
    final int statusCode = response.statusCode ?? 500;

    // Log the raw response for debugging purposes
    AppLogger.info(
      'API Response [${response.request?.url}] - Status: $statusCode, Body: ${response.bodyString}',
    );

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
}
