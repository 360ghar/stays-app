// Sign-out and account deletion: the order of the calls, the local stores that
// must not outlive the session, and the legacy profile copy.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stays_app/app/data/providers/auth/i_auth_provider.dart';
import 'package:stays_app/app/data/providers/users_provider.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/data/services/push_notification_service.dart';
import 'package:stays_app/app/data/services/storage_service.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/core/providers/data_providers.dart';
import 'package:stays_app/features/auth/providers/auth_providers.dart';

import '../contract/support/wire.dart';

/// Records the calls of the session end, in order.
class _Calls {
  final log = <String>[];
}

class _FakeRepository extends Fake implements AuthRepository {
  _FakeRepository(this.calls, {this.deleteError});

  final _Calls calls;
  final ApiException? deleteError;

  @override
  Future<void> logout() async => calls.log.add('logout');

  @override
  Future<void> deleteAccount() async {
    calls.log.add('delete');
    final error = deleteError;
    if (error != null) throw error;
  }
}

class _FakePush extends Fake implements PushNotificationService {
  _FakePush(this.calls);

  final _Calls calls;

  @override
  Future<void> unregisterDevice() async => calls.log.add('unregister');
}

/// A provider with no session. It must not need anything else.
class _SignedOutProvider extends Fake implements IAuthProvider {
  @override
  Future<Map<String, dynamic>?> getCurrentUserRaw() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  group('sign-out and account deletion', () {
    ProviderContainer container(_Calls calls, {ApiException? deleteError}) {
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeRepository(calls, deleteError: deleteError),
          ),
          pushNotificationServiceProvider.overrideWithValue(_FakePush(calls)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('logout unregisters the device before the session ends', () async {
      final calls = _Calls();
      await container(calls).read(authProvider.notifier).logout();
      // The unregister route needs the session, so it runs first.
      expect(calls.log, ['unregister', 'logout']);
    });

    test('deleting the account ends the session after the backend', () async {
      final calls = _Calls();
      final c = container(calls);
      final deleted = await c.read(authProvider.notifier).deleteAccount();
      expect(deleted, isTrue);
      expect(calls.log, ['unregister', 'delete', 'logout']);
      expect(c.read(authProvider).status, AuthStatus.idle);
    });

    test('a refused deletion keeps the session and shows the reason', () async {
      final calls = _Calls();
      final c = container(
        calls,
        deleteError: ApiException(
          message: 'The account cannot be deleted now.',
          statusCode: 409,
          code: 'ACCOUNT_BUSY',
        ),
      );
      final deleted = await c.read(authProvider.notifier).deleteAccount();
      expect(deleted, isFalse);
      // No sign-out: the guest is still signed in and can try again.
      expect(calls.log, ['unregister', 'delete']);
      final state = c.read(authProvider);
      expect(state.status, AuthStatus.error);
      expect(state.error, 'The account cannot be deleted now.');
    });
  });

  test('a service that was never started sends no unregister call', () async {
    // Nothing starts the push service yet (the backend sends no push to
    // stays), so a sign-out must not wait on it or call the backend.
    final adapter = RecordingAdapter((_) => const FakeReply(null, status: 204));
    final service = PushNotificationService(
      StorageService(),
      usersProvider: UsersProvider(dio: fakeDio(adapter)),
    );
    await service.unregisterDevice();
    expect(adapter.requests, isEmpty);
  });

  group('profile copy on the device', () {
    test('start-up removes the old user_data copy of the profile', () async {
      SharedPreferences.setMockInitialValues({
        'user_data': jsonEncode({
          'id': '50',
          'email': 'asha@example.com',
          'phone': '+919800000000',
        }),
        'theme_mode': 'dark',
      });
      await StorageService().initialize();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('user_data'), isFalse);
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('a signed-out device has no current user', () async {
      SharedPreferences.setMockInitialValues({
        'user_data': jsonEncode({'id': '50', 'email': 'asha@example.com'}),
      });
      final repository = AuthRepository(
        provider: _SignedOutProvider(),
        storage: StorageService(),
      );
      // The profile of the last account is never read back.
      expect(await repository.getCurrentUser(), isNull);
    });
  });
}
