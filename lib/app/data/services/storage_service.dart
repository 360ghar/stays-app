import 'dart:convert';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  factory StorageService() => _shared;
  StorageService._internal();

  // Shared instance so the whole app uses the same backing store.
  // Use [StorageService()] everywhere.
  static final StorageService _shared = StorageService._internal();

  // Completes when initialize() finishes so dependents can await readiness
  static final Completer<void> _ready = Completer<void>();
  static Future<void> get ready => _ready.future;
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userDataKey = 'user_data';

  SharedPreferences? _prefs;
  late FlutterSecureStorage _secureStorage;
  bool _initialized = false;

  Future<StorageService> initialize() async {
    if (_initialized) return this;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      _secureStorage = const FlutterSecureStorage();
      _initialized = true;
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
  // DEPRECATED: Prefer using TokenService for token operations
  static const _tokenExpiresAtKey = 'token_expires_at';

  @Deprecated(
    'Use TokenService.storeTokens() instead for centralized token management',
  )
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? expiresAt,
  }) async {
    await _writeSecure(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await _writeSecure(_refreshTokenKey, refreshToken);
    }
    if (expiresAt != null) {
      await _writeSecure(_tokenExpiresAtKey, expiresAt);
    } else {
      await _deleteSecure(_tokenExpiresAtKey);
    }
  }

  @Deprecated('Use TokenService.accessToken instead')
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  @Deprecated('Use TokenService.refreshToken instead')
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  @Deprecated('Use TokenService.tokenExpiration instead')
  Future<String?> getTokenExpiration() async {
    return await _secureStorage.read(key: _tokenExpiresAtKey);
  }

  @Deprecated('Use TokenService.hasValidToken instead')
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @Deprecated('Use TokenService.clearTokens() instead')
  Future<void> clearTokens() async {
    await _deleteSecure(_accessTokenKey);
    await _deleteSecure(_refreshTokenKey);
    await _deleteSecure(_tokenExpiresAtKey);
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

  // User data management. SECURITY CONTRACT: user-data is non-sensitive
  // profile JSON only — tokens live exclusively in flutter_secure_storage via
  // TokenService.storeTokens. The assert below enforces the separation.
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    assert(
      !jsonEncode(userData).contains('accessToken'),
      'saveUserData must never persist tokens; use TokenService.storeTokens instead',
    );
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final raw = prefs.getString(_userDataKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearUserData() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  // Cache management (non-sensitive data)
  Future<void> cache(String key, Map<String, dynamic> value) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString('cache_$key', jsonEncode(value));
  }

  Future<Map<String, dynamic>?> getCached(String key) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final raw = prefs.getString('cache_$key');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
