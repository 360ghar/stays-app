import 'package:get/get.dart';

import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../../utils/logger/app_logger.dart';

class LoginResponse {
  final UserModel user;
  final String accessToken;
  final String? refreshToken;
  final String tokenType;

  LoginResponse({
    required this.user, 
    required this.accessToken, 
    this.refreshToken,
    this.tokenType = 'Bearer',
  });

  factory LoginResponse.fromMap(Map<String, dynamic> map) {
    AppLogger.debug('Parsing login response: $map');
    
    final userJson = (map['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    // Parse user data from the response
    final user = UserModel(
      id: userJson['id']?.toString() ?? '',
      email: userJson['email'] as String?,
      phone: userJson['phone'] as String?,
      firstName: userJson['firstName'] as String?,
      lastName: userJson['lastName'] as String?,
      name: userJson['name'] as String?,
    );

    return LoginResponse(
      user: user,
      accessToken: map['access_token'] as String,
      refreshToken: map['refresh_token'] as String?,
      tokenType: map['token_type'] as String? ?? 'Bearer',
    );
  }
}

class AuthRepository {
  final AuthProvider _provider;
  // Resolve StorageService within repository to avoid changing bindings
  final StorageService _storage = Get.find<StorageService>();

  AuthRepository({required AuthProvider provider}) : _provider = provider;

  Future<UserModel> loginWithEmail({required String email, required String password}) async {
    final json = await _provider.loginWithEmail(email: email, password: password);
    final result = LoginResponse.fromMap(json);
    await _persistTokens(result.accessToken, result.refreshToken);
    await _persistUserData(result.user);
    return result.user;
  }

  Future<UserModel> loginWithPhone({required String phone, required String password}) async {
    final json = await _provider.loginWithPhone(phone: phone, password: password);
    final result = LoginResponse.fromMap(json);
    await _persistTokens(result.accessToken, result.refreshToken);
    await _persistUserData(result.user);
    return result.user;
  }

  Future<UserModel> register({required String name, required String email, required String password}) async {
    final json = await _provider.register(name: name, email: email, password: password);
    final result = LoginResponse.fromMap(json);
    await _persistTokens(result.accessToken, result.refreshToken);
    await _persistUserData(result.user);
    return result.user;
  }

  Future<void> logout() async {
    final refresh = await _storage.getRefreshToken();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _provider.logout(refresh);
      }
    } catch (e) {
      AppLogger.warning('Logout API call failed: $e');
    } finally {
      await _storage.clearTokens();
      await _storage.clearUserData();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final userData = await _storage.getUserData();
    if (userData != null) {
      return UserModel.fromMap(userData);
    }
    return null;
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _persistTokens(String accessToken, String? refreshToken) async {
    await _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
  }
  
  Future<void> _persistUserData(UserModel user) async {
    await _storage.saveUserData(user.toMap());
  }
}
