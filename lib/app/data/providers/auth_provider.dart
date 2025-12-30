import 'auth/i_auth_provider.dart';
import 'base_provider.dart';
import '../../utils/logger/app_logger.dart';

class AuthProvider extends BaseProvider implements IAuthProvider {
  @override
  Future<ProviderAuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await post('/auth/login/', {
      'email': email,
      'password': password,
    });
    return handleResponse(response, (json) {
      final map = Map<String, dynamic>.from(json as Map);
      return ProviderAuthResult(
        accessToken:
            map['accessToken']?.toString() ?? map['access_token']?.toString(),
        refreshToken:
            map['refreshToken']?.toString() ?? map['refresh_token']?.toString(),
        rawUser: _extractUser(map),
      );
    });
  }

  @override
  Future<ProviderAuthResult> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final response = await post('/auth/login/', {
      'phone': phone,
      'password': password,
    });
    return handleResponse(response, (json) {
      final map = Map<String, dynamic>.from(json as Map);
      return ProviderAuthResult(
        accessToken:
            map['accessToken']?.toString() ?? map['access_token']?.toString(),
        refreshToken:
            map['refreshToken']?.toString() ?? map['refresh_token']?.toString(),
        rawUser: _extractUser(map),
      );
    });
  }

  @override
  Future<ProviderAuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    return handleResponse(response, (json) {
      final map = Map<String, dynamic>.from(json as Map);
      return ProviderAuthResult(
        accessToken:
            map['accessToken']?.toString() ?? map['access_token']?.toString(),
        refreshToken:
            map['refreshToken']?.toString() ?? map['refresh_token']?.toString(),
        rawUser: _extractUser(map),
      );
    });
  }

  @override
  Future<void> logout() async {
    try {
      final response = await post('/auth/logout', {});
      handleResponse(response, (json) => json);
    } catch (e) {
      AppLogger.warning('Logout call failed, proceeding to clear tokens.', e);
    }
  }

  @override
  Future<bool> signUpWithPhone({
    required String phone,
    required String password,
  }) async {
    final response = await post('/auth/register', {
      'phone': phone,
      'password': password,
    });
    return handleResponse(response, (json) => true);
  }

  @override
  Future<void> updatePassword({
    required String newPassword,
    String? currentPassword,
  }) async {
    final response = await post('/auth/update-password', {
      'password': newPassword,
      if (currentPassword != null) 'current_password': currentPassword,
    });
    handleResponse(response, (json) => null);
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUserRaw() async {
    final response = await get('/auth/me');
    return handleResponse(response, (json) {
      return json is Map<String, dynamic> ? json : <String, dynamic>{};
    });
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final me = await getCurrentUserRaw();
      return me != null;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? _extractUser(Map<String, dynamic> map) {
    final data = map['user'] ?? map['data'];
    if (data is Map<String, dynamic>) return data;
    return null;
  }
}
