import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class StorageService {
  static const _boxName = 'app_storage';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  late final GetStorage _box;

  Future<void> initialize() async {
    await GetStorage.init(_boxName);
    _box = GetStorage(_boxName);
  }

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _box.write(_accessTokenKey, accessToken);
    await _box.write(_refreshTokenKey, refreshToken);
  }

  Future<String?> getAccessToken() async => _box.read<String>(_accessTokenKey);
  Future<String?> getRefreshToken() async => _box.read<String>(_refreshTokenKey);

  Future<void> clearTokens() async {
    await _box.remove(_accessTokenKey);
    await _box.remove(_refreshTokenKey);
  }

  Future<void> cache(String key, Map<String, dynamic> value) async {
    await _box.write('cache_$key', jsonEncode(value));
  }

  Future<Map<String, dynamic>?> getCached(String key) async {
    final raw = _box.read<String>('cache_$key');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}

