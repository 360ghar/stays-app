import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/data/services/push_notification_service.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/core/providers/data_providers.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/features/profile/views/profile_screen.dart';

import '../contract/support/wire.dart';

class _FakeRepository extends Fake implements AuthRepository {
  _FakeRepository({this.deleteError});

  final ApiException? deleteError;
  final log = <String>[];

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<void> deleteAccount() async {
    log.add('delete');
    final error = deleteError;
    if (error != null) throw error;
  }

  @override
  Future<void> logout() async => log.add('logout');
}

class _FakePush extends Fake implements PushNotificationService {
  @override
  Future<void> unregisterDevice() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  Future<_FakeRepository> pumpProfile(
    WidgetTester tester, {
    ApiException? deleteError,
  }) async {
    final repository = _FakeRepository(deleteError: deleteError);
    final router = GoRouter(
      initialLocation: AppPaths.profile,
      routes: [
        GoRoute(
          path: AppPaths.profile,
          builder: (_, _) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppPaths.login,
          builder: (_, _) => const Scaffold(body: Text('Login page')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          pushNotificationServiceProvider.overrideWithValue(_FakePush()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('Cancel keeps the account', (tester) async {
    final repository = await pumpProfile(tester);

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.log, isEmpty);
    expect(find.text('Delete account?'), findsNothing);
    expect(find.text('Login page'), findsNothing);
  });

  testWidgets('Delete removes the account and returns to login', (
    tester,
  ) async {
    final repository = await pumpProfile(tester);

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.log, ['delete', 'logout']);
    expect(find.text('Login page'), findsOneWidget);
  });

  testWidgets('A refusal shows the reason and keeps the screen', (
    tester,
  ) async {
    final repository = await pumpProfile(
      tester,
      deleteError: ApiException(
        message: 'The account cannot be deleted now.',
        statusCode: 409,
        code: 'ACCOUNT_BUSY',
      ),
    );

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.log, ['delete']);
    expect(find.text('The account cannot be deleted now.'), findsOneWidget);
    expect(find.text('Login page'), findsNothing);
  });
}
