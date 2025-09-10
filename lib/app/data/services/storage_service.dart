import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService extends GetxService {
  static const _boxName = 'app_storage';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userDataKey = 'user_data';

  late final GetStorage _box;
  late FlutterSecureStorage _secureStorage;

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  Future<StorageService> initialize() async {
    await GetStorage.init(_boxName);
    _box = GetStorage(_boxName);
    _secureStorage = const FlutterSecureStorage(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    return this;
  }

  // Secure token management
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }
    // Sync to temp storage for middleware
    await _syncTokensToTemp();
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }
  
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }
  
  // Synchronous versions for middleware (fallback to async)
  String? getAccessTokenSync() {
    // Note: This should be avoided, but kept for backward compatibility
    // Consider refactoring middleware to be async
    return _box.read<String>('temp_$_accessTokenKey');
  }
  
  String? getRefreshTokenSync() {
    return _box.read<String>('temp_$_refreshTokenKey');
  }
  
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  // Legacy sync version
  bool hasAccessTokenSync() {
    return getAccessTokenSync() != null;
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _box.remove('temp_$_accessTokenKey');
    await _box.remove('temp_$_refreshTokenKey');
  }
  
  // User data management
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _box.write(_userDataKey, jsonEncode(userData));
  }
  
  Future<Map<String, dynamic>?> getUserData() async {
    final raw = _box.read<String>(_userDataKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
  
  Future<void> clearUserData() async {
    await _box.remove(_userDataKey);
  }
  
  // Sync tokens to temp storage for middleware (called after login)
  Future<void> _syncTokensToTemp() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    if (accessToken != null) {
      await _box.write('temp_$_accessTokenKey', accessToken);
    }
    if (refreshToken != null) {
      await _box.write('temp_$_refreshTokenKey', refreshToken);
    }
  }

  // Cache management (non-sensitive data)
  Future<void> cache(String key, Map<String, dynamic> value) async {
    await _box.write('cache_$key', jsonEncode(value));
  }

  Future<Map<String, dynamic>?> getCached(String key) async {
    final raw = _box.read<String>('cache_$key');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}

