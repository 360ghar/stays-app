import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/services/storage_service.dart';
import 'package:stays_app/app/utils/services/token_service.dart';

/// Hand-written fake (no mockito) so this test file compiles fast.
class _FakeStorage implements StorageService {
  String? accessToken;
  String? refreshToken;
  String? expiresAt;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<StorageService> initialize() async => this as StorageService;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<String?> getTokenExpiration() async => expiresAt;

  @override
  Future<bool> hasAccessToken() async =>
      (await getAccessToken())?.isNotEmpty ?? false;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? expiresAt,
  }) async {
    saveCalls++;
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.expiresAt = expiresAt;
  }

  @override
  Future<void> clearTokens() async {
    clearCalls++;
    accessToken = null;
    refreshToken = null;
    expiresAt = null;
  }

  @override
  Future<void> clearUserData() async {}

  @override
  Future<void> cache(String key, Map<String, dynamic> value) async {}

  @override
  Future<Map<String, dynamic>?> getCached(String key) async => null;
}

void main() {
  /// Creates the service AFTER the storage stubs are in place and awaits its
  /// self-kicking initialization so it reads the intended state.
  Future<TokenService> createService(_FakeStorage storage) async {
    final service = TokenService(storageService: storage);
    await service.ready;
    return service;
  }

  test('starts unauthenticated', () async {
    final storage = _FakeStorage();
    final service = await createService(storage);
    expect(service.isAuthenticated.value, isFalse);
    expect(service.isReady, isTrue);
    service.dispose();
  });

  test('storeTokens persists tokens and flips auth state', () async {
    final storage = _FakeStorage();
    final service = await createService(storage);

    await service.storeTokens(
      accessToken: 'aaa.bbb.ccc',
      refreshToken: 'refresh-1',
    );

    expect(service.isAuthenticated.value, isTrue);
    expect(service.hasValidToken, isTrue);
    expect(service.refreshToken, 'refresh-1');
    expect(storage.saveCalls, 1);
    expect(storage.accessToken, 'aaa.bbb.ccc');
    service.dispose();
  });

  test('clearTokens resets auth state and storage', () async {
    final storage = _FakeStorage();
    final service = await createService(storage);
    await service.storeTokens(
      accessToken: 'aaa.bbb.ccc',
      refreshToken: 'refresh-1',
    );
    expect(service.isAuthenticated.value, isTrue);

    await service.clearTokens();
    expect(service.isAuthenticated.value, isFalse);
    expect(service.hasValidToken, isFalse);
    expect(storage.clearCalls, 1);
    expect(storage.accessToken, isNull);
    service.dispose();
  });

  test('loads a valid stored token on initialization', () async {
    final storage = _FakeStorage()
      ..accessToken = 'aaa.bbb.ccc'
      ..refreshToken = 'refresh-1'
      ..expiresAt = DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String();

    final service = await createService(storage);
    expect(service.isAuthenticated.value, isTrue);
    expect(service.accessToken, 'aaa.bbb.ccc');
    service.dispose();
  });

  test('rejects malformed stored tokens and clears them', () async {
    final storage = _FakeStorage()..accessToken = 'not-a-jwt';

    final service = await createService(storage);
    expect(service.isAuthenticated.value, isFalse);
    expect(storage.clearCalls, 1);
    service.dispose();
  });

  group('TokenInfo', () {
    test('isExpired respects a 5-minute buffer', () {
      final token = TokenInfo(
        accessToken: 'a.b.c',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 2)),
      );
      expect(token.isExpired, isTrue);
    });

    test('round-trips through JSON', () {
      final token = TokenInfo(
        accessToken: 'a.b.c',
        refreshToken: 'r',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
      );
      final restored = TokenInfo.fromJson(token.toJson());
      expect(restored.accessToken, token.accessToken);
      expect(restored.refreshToken, token.refreshToken);
      expect(restored.expiresAt, token.expiresAt);
    });
  });

  test('validateTokenFormat accepts JWT-like tokens only', () async {
    final service = await createService(_FakeStorage());
    expect(service.validateTokenFormat('aaa.bbb.ccc'), isTrue);
    expect(service.validateTokenFormat('not-a-token'), isFalse);
    expect(service.validateTokenFormat('a.b'), isFalse);
    expect(service.validateTokenFormat(null), isFalse);
    service.dispose();
  });
}
