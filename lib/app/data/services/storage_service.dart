import 'dart:convert';
import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService extends GetxService {
  // Completes when initialize() finishes so dependents can await readiness
  static final Completer<void> _ready = Completer<void>();
  static Future<void> get ready => _ready.future;
  static const _boxName = 'app_storage';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userDataKey = 'user_data';

  late final GetStorage _box;
  late FlutterSecureStorage _secureStorage;


  Future<StorageService> initialize() async {
    try {
      await GetStorage.init(_boxName);
      _box = GetStorage(_boxName);
      _secureStorage = const FlutterSecureStorage();
      if (!_ready.isCompleted) {
        _ready.complete();
      }
      return this;
    } catch (e) {
      if (!_ready.isCompleted) {
        _ready.completeError(e);
      }
      rethrow;
    }
  }

  // Secure token management
  static const _tokenExpiresAtKey = 'token_expires_at';

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? expiresAt,
  }) async {
    // Write with duplicate-safe fallback for iOS Keychain (-25299)
    await _writeSecure(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await _writeSecure(_refreshTokenKey, refreshToken);
    }
    if (expiresAt != null) {
      await _writeSecure(_tokenExpiresAtKey, expiresAt);
    } else {
      await _deleteSecure(_tokenExpiresAtKey);
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

  Future<String?> getTokenExpiration() async {
    return await _secureStorage.read(key: _tokenExpiresAtKey);
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearTokens() async {
    await _deleteSecure(_accessTokenKey);
    await _deleteSecure(_refreshTokenKey);
    await _deleteSecure(_tokenExpiresAtKey);
    // No temp cache of tokens
  }

  Future<void> _writeSecure(String key, String? value) async {
    if (value == null) {
      await _deleteSecure(key);
      return;
    }
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      // Handle iOS duplicate item error (-25299) by deleting then retrying
      final msg = e.toString();
      if (msg.contains('-25299') ||
          msg.contains('already exists in the keychain')) {
        await _deleteSecure(key);
        await _secureStorage.write(key: key, value: value);
        return;
      }
      rethrow;
    }
  }

  Future<void> _deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {
      // Fallback: try deleting with default iOS options in case accessibility changed
      try {
        const fallback = FlutterSecureStorage();
        await fallback.delete(key: key);
      } catch (_) {}
    }
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

  // Deprecated: temp sync removed for security. Kept as a no-op to avoid breakage.
  Future<void> _syncTokensToTemp() async {}

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
