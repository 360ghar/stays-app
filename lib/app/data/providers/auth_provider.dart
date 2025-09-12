import 'base_provider.dart';

class AuthProvider extends BaseProvider {
  /// Login with email & password
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await post('/auth/login/', {
      'email': email,
      'password': password,
    });
    return handleResponse(response, (json) => json as Map<String, dynamic>);
  }

  /// Login with phone & password (if backend supports phone login on same endpoint)
  Future<Map<String, dynamic>> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final response = await post('/auth/login/', {
      'phone': phone,
      'password': password,
    });
    return handleResponse(response, (json) => json as Map<String, dynamic>);
  }

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    return handleResponse(response, (json) => json as Map<String, dynamic>);
  }

  /// Logout using a refresh token (or access token if backend requires)
  Future<void> logout(String refreshToken) async {
    final response = await post('/auth/logout', {
      'refreshToken': refreshToken,
    });
    handleResponse(response, (json) => json);
  }
}
