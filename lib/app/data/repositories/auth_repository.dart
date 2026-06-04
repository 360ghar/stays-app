import 'package:get/get.dart';

import '../services/storage_service.dart';
import '../../utils/services/token_service.dart';
import '../models/user_model.dart';
import '../../utils/logger/app_logger.dart';
import '../../utils/exceptions/app_exceptions.dart';
import '../providers/auth/i_auth_provider.dart';

class AuthRepository {
  final IAuthProvider _provider;
  final StorageService _storage = Get.find<StorageService>();

  AuthRepository({required IAuthProvider provider}) : _provider = provider;

  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _provider.loginWithEmail(
        email: email,
        password: password,
      );
      await _persistTokens(res);
      final user = _mapUser(res.rawUser);
      await _persistUserData(user);
      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  Future<UserModel> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      final res = await _provider.loginWithPhone(
        phone: phone,
        password: password,
      );
      await _persistTokens(res);
      final user = _mapUser(res.rawUser);
      await _persistUserData(user);
      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _provider.register(
        name: name,
        email: email,
        password: password,
      );
      await _persistTokens(res);
      final user = _mapUser(res.rawUser);
      await _persistUserData(user);
      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  Future<bool> signUpWithPhone({
    required String phone,
    required String password,
  }) => _provider.signUpWithPhone(phone: phone, password: password);

  Future<void> updatePassword({
    required String newPassword,
    String? currentPassword,
  }) => _provider.updatePassword(
    newPassword: newPassword,
    currentPassword: currentPassword,
  );

  Future<void> logout() async {
    try {
      await _provider.logout();
    } finally {
      try {
        final tokenService = Get.find<TokenService>();
        await tokenService.ready;
        await tokenService.clearTokens();
      } catch (_) {
        await _storage.clearTokens();
      }
      await _storage.clearUserData();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final raw = await _provider.getCurrentUserRaw();
    if (raw != null) {
      final user = _mapUser(raw);
      await _persistUserData(user);
      return user;
    }
    final userData = await _storage.getUserData();
    if (userData != null) {
      return UserModel.fromMap(userData);
    }
    return null;
  }

  Future<bool> isAuthenticated() => _provider.isAuthenticated();

  // Helpers
  UserModel _mapUser(Map<String, dynamic>? raw) {
    final m = raw ?? const <String, dynamic>{};
    return UserModel(
      id: (m['id'] ?? m['user_id'] ?? '').toString(),
      email: m['email'] as String?,
      phone: m['phone'] as String?,
      firstName: m['first_name'] as String?,
      lastName: m['last_name'] as String?,
      name: (m['full_name'] as String?) ?? (m['name'] as String?),
    );
  }

  Future<void> _persistTokens(ProviderAuthResult res) async {
    if (res.accessToken == null) return;
    try {
      final tokenService = Get.find<TokenService>();
      await tokenService.ready;
      await tokenService.storeTokens(
        accessToken: res.accessToken!,
        refreshToken: res.refreshToken,
      );
    } catch (e) {
      AppLogger.warning('Failed to persist tokens: $e');
    }
  }

  Future<void> _persistUserData(UserModel user) =>
      _storage.saveUserData(user.toMap());
}
