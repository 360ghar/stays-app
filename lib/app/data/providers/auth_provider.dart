import 'base_provider.dart';

class AuthProvider extends BaseProvider {
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final response = await post('/auth/login', {'email': email, 'password': password});
    return handleResponse(response, (json) => json as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) async {
    final response = await post('/auth/logout', {'refreshToken': refreshToken});
    handleResponse(response, (json) => json);
  }
}

