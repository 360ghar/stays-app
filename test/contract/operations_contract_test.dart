// Every route the app calls exists in the backend OpenAPI document. No
// payment route is called: all six /payments routes are gone.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/wire.dart';

/// The operations the app calls (`METHOD path`).
const _calls = <String>[
  'GET /api/v1/properties',
  'GET /api/v1/properties/{property_id}',
  'GET /api/v1/properties/recommendations',
  'GET /api/v1/swipes',
  'POST /api/v1/swipes',
  'POST /api/v1/swipes/batch-remove',
  'GET /api/v1/bookings',
  'POST /api/v1/bookings',
  'GET /api/v1/bookings/{booking_id}',
  'POST /api/v1/bookings/cancel',
  'POST /api/v1/bookings/review',
  'POST /api/v1/bookings/calculate-pricing',
  'POST /api/v1/bookings/check-availability',
  'GET /api/v1/bookings/{booking_id}/messages',
  'POST /api/v1/bookings/{booking_id}/messages',
  'GET /api/v1/users/profile',
  'PUT /api/v1/users/profile',
  'PUT /api/v1/users/preferences',
  'PUT /api/v1/users/notifications',
  'PUT /api/v1/users/privacy-settings',
  'PUT /api/v1/users/location',
  'POST /api/v1/users/me/avatar',
  'DELETE /api/v1/users/me',
  'GET /api/v1/users/me/auth-state',
  'POST /api/v1/users/me/onboarding',
  'POST /api/v1/auth/identifier-status',
  'POST /api/v1/auth/last-method',
  'POST /api/v1/bugs',
  'POST /api/v1/notifications/devices/register',
  'DELETE /api/v1/notifications/devices/unregister',
];

String _template(String path) => path.replaceAll(RegExp(r'\{[^}]+\}'), '{}');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  final operations = fixture('operations');

  for (final call in _calls) {
    test('$call exists in the backend document', () {
      expect(operations.containsKey(call), isTrue);
    });
  }

  test('the backend document has no /payments route', () {
    // PM rent payments (/pm/rent/payments) are another feature and stay.
    expect(
      operations.keys.where(
        (k) => k.split(' ').last.startsWith('/api/v1/payments'),
      ),
      isEmpty,
    );
  });

  test('every /api/v1 path in lib is a backend route', () {
    final known = {
      for (final key in operations.keys) _template(key.split(' ').last),
    };
    final literal = RegExp(r"""['"](/api/v1/[A-Za-z0-9_\-/$\{\}]+)""");
    final unknown = <String>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final match in literal.allMatches(file.readAsStringSync())) {
        // `$id` and `${expr}` stand for a path parameter.
        final path = match
            .group(1)!
            .replaceAll(RegExp(r'\$\{[^}]*\}|\$[A-Za-z_]+'), '{}');
        if (!known.contains(_template(path))) {
          unknown.add('$path in ${file.path}');
        }
      }
    }
    expect(unknown, isEmpty);
  });

  test('no payment or Razorpay code is left in lib', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final text = file.readAsStringSync().toLowerCase();
      if (text.contains('razorpay') || text.contains('/payments')) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test(
    'chat and every other read go through the backend, not Supabase tables',
    () {
      final offenders = <String>[];
      final table = RegExp(r'\.from\(\s*[\x27\x22]');
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final text = file.readAsStringSync();
        if (table.hasMatch(text) || text.contains('onPostgresChanges')) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty);
    },
  );

  test('no payment screen route is left', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    expect(router, isNot(contains('/payment')));
  });
}
