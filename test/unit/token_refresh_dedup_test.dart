import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/services/storage_service.dart';
import 'package:stays_app/app/utils/services/token_service.dart';

/// Extension of token_service_test.dart: proves concurrent refresh callers
/// share one in-flight round-trip (dedup), while sequential refreshes each
/// run. Supabase is never initialized here, so every refresh attempt fails
/// locally with `false` — no real network, no timers.
class _FakeStorage implements StorageService {
  int clearCalls = 0;

  @override
  Future<StorageService> initialize() async => this as StorageService;

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<String?> getTokenExpiration() async => null;

  @override
  Future<bool> hasAccessToken() async => false;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? expiresAt,
  }) async {}

  @override
  Future<void> clearTokens() async {
    clearCalls++;
  }

  @override
  Future<void> clearUserData() async {}

  @override
  Future<void> cache(String key, Map<String, dynamic> value) async {}

  @override
  Future<Map<String, dynamic>?> getCached(String key) async => null;
}

Future<TokenService> _createService(_FakeStorage storage) async {
  final service = TokenService(storageService: storage);
  await service.ready;
  return service;
}

void main() {
  test('concurrent performTokenRefresh calls share one flight', () async {
    final storage = _FakeStorage();
    final service = await _createService(storage);

    // Start both without awaiting so the second joins the in-flight future.
    final first = service.performTokenRefresh();
    final second = service.performTokenRefresh();
    final results = await Future.wait([first, second]);

    expect(results, [false, false]);
    // One underlying refresh => exactly one clearTokens side effect.
    expect(storage.clearCalls, 1);
    service.dispose();
  });

  test('sequential performTokenRefresh calls each run independently', () async {
    final storage = _FakeStorage();
    final service = await _createService(storage);

    expect(await service.performTokenRefresh(), isFalse);
    expect(await service.performTokenRefresh(), isFalse);
    expect(storage.clearCalls, 2);
    service.dispose();
  });

  test('refresh() alias dedups with performTokenRefresh', () async {
    final storage = _FakeStorage();
    final service = await _createService(storage);

    final a = service.refresh();
    final b = service.performTokenRefresh();
    final results = await Future.wait([a, b]);

    expect(results, [false, false]);
    expect(storage.clearCalls, 1);
    service.dispose();
  });
}
