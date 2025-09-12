import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../utils/logger/app_logger.dart';
import '../services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/exceptions/app_exceptions.dart';

abstract class BaseProvider extends GetConnect {
  final StorageService _storage = Get.find<StorageService>();

  @override
  void onInit() {
    httpClient.baseUrl = AppConfig.I.apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 30);

    httpClient.addRequestModifier<Object?>((request) async {
      // Prefer Supabase session token; fallback to legacy storage
      final supabaseToken = Supabase.instance.client.auth.currentSession?.accessToken;
      final legacyToken = _storage.getAccessTokenSync() ?? await _storage.getAccessToken();
      final token = supabaseToken ?? legacyToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      } else {
        request.headers.remove('Authorization');
      }
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';
      AppLogger.logRequest({'method': request.method, 'url': request.url.toString()});
      return request;
    });

    httpClient.addResponseModifier<Object?>((request, response) async {
      AppLogger.logResponse({'status': response.statusCode, 'url': request.url.toString()});
      
      // Handle 401 unauthorized - redirect to login
      if (response.statusCode == 401 && !_isAuthEndpoint(request.url)) {
        AppLogger.warning('Token expired, redirecting to login');
        await _storage.clearTokens();
        await _storage.clearUserData();
        Get.offAllNamed('/login');
      }
      
      return response;
    });
    super.onInit();
  }

  T handleResponse<T>(Response response, T Function(dynamic) parser) {
    final int statusCode = response.statusCode ?? 500;

    // Log the raw response for debugging purposes
    AppLogger.info('API Response [${response.request?.url}] - Status: $statusCode, Body: ${response.bodyString}');

    if (response.isOk) {
      // SUCCESS CASE (Status codes 200-299)
      if (response.body == null) {
        // This can happen on successful logout or delete requests
        return parser(null);
      }
      return parser(response.body);
    } else {
      // ERROR CASE (Status codes 4xx, 5xx)
      String errorMessage = 'An unknown error occurred.';
      
      // Try to parse a specific error message from the backend response
      if (response.body != null && response.body is Map<String, dynamic>) {
        final body = response.body as Map<String, dynamic>;
        // Look for common error keys like "message" or "detail" (FastAPI uses "detail")
        errorMessage = body['detail'] as String? ?? 
                      body['message'] as String? ?? 
                      body['error'] as String? ?? 
                      'The server returned an error.';
      } else if (response.bodyString != null && response.bodyString!.isNotEmpty) {
        errorMessage = response.bodyString!;
      } else if (response.statusText != null) {
        errorMessage = response.statusText!;
      }
      
      // Log the error for debugging
      AppLogger.error('API Error Response', 'Status: $statusCode, Message: $errorMessage');
      
      // Throw our custom exception with the real status code and message
      throw ApiException(
        message: errorMessage,
        statusCode: statusCode,
      );
    }
  }

  /// Check if the current request is for auth endpoints
  bool _isAuthEndpoint(Uri url) {
    return url.path.contains('/auth/') ||
           url.path.contains('/login') ||
           url.path.contains('/register');
  }
}
