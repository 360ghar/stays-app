import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/models/user_model.dart';

void main() {
  group('UserModel.fromMap robustness', () {
    test('parses bool fields from int and string representations', () {
      final user = UserModel.fromMap(const {
        'id': 'u1',
        'is_active': 1,
        'is_verified': 'true',
        'is_super_host': 0,
      });

      expect(user.isActive, isTrue);
      expect(user.isVerified, isTrue);
      expect(user.isSuperHost, isFalse);
    });

    test('does not throw on absent optional fields', () {
      final user = UserModel.fromMap(const {'id': 'u1'});
      expect(user.email, isNull);
      expect(user.phone, isNull);
      expect(user.firstName, isNull);
      expect(user.dateOfBirth, isNull);
      expect(user.isActive, isNull);
    });

    test('handles numeric string fields without throwing', () {
      final user = UserModel.fromMap(const {
        'id': 'u1',
        'current_latitude': '19.0760',
        'current_longitude': 72.8777,
        'date_of_birth': '1995-04-10',
      });
      expect(user.currentLatitude, 19.0760);
      expect(user.currentLongitude, 72.8777);
      // Date-only values parse as UTC (see JsonHelpers._dateOnlyPattern).
      expect(user.dateOfBirth, DateTime.utc(1995, 4, 10));
    });

    test('prefers snake_case over camelCase consistently', () {
      final user = UserModel.fromMap(const {
        'id': 'u1',
        'first_name': 'Ada',
        'lastName': 'Lovelace',
        'full_name': 'Ada Lovelace',
      });
      expect(user.firstName, 'Ada');
      expect(user.lastName, 'Lovelace');
      expect(user.name, 'Ada Lovelace');
    });
  });
}
