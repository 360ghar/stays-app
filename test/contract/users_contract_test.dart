// Contract tests for the user, auth and device routes the app calls.

import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/data/models/feedback_model.dart';
import 'package:stays_app/app/data/models/wire_enums.dart';
import 'package:stays_app/app/data/providers/auth_api_provider.dart';
import 'package:stays_app/app/data/providers/users_provider.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';

import 'support/wire.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  final users = fixture('users');
  final auth = fixture('auth');

  group('users', () {
    test('GET /users/profile parses SelfUser', () async {
      final adapter = RecordingAdapter((_) => FakeReply(users['profile']));
      final user = await UsersProvider(dio: fakeDio(adapter)).getProfile();
      expect(user.id, '50');
      expect(user.name, 'Asha Verma');
      expect(user.email, 'asha@example.com');
      expect(user.phone, '+919800000000');
      expect(user.supabaseId, '0f5e8d9a-1c2b-4d3e-8f7a-6b5c4d3e2f1a');
      expect(user.profileImageUrl, 'https://cdn.example.com/u/50.jpg');
      expect(user.dateOfBirth, DateTime.utc(1994, 2, 11));
      expect(user.currentLatitude, 15.51);
      expect(user.agentId, '4');
    });

    test('a profile with every optional field null still parses', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(users['profile_minimal']),
      );
      final user = await UsersProvider(dio: fakeDio(adapter)).getProfile();
      expect(user.id, '50');
      expect(user.email, isNull);
      expect(user.name, isNull);
    });

    test('PUT /users/profile sends only UserUpdate keys', () async {
      final adapter = RecordingAdapter((_) => FakeReply(users['profile']));
      await UsersProvider(dio: fakeDio(adapter)).updateProfile(
        fullName: ' Asha Verma ',
        phone: '+919800000000',
        dateOfBirth: DateTime(1994, 2, 11),
      );
      final body = obj(adapter.last.data);
      expectBodyMatches('UserUpdate', body);
      expect(body, {
        'full_name': 'Asha Verma',
        'phone': '+919800000000',
        'date_of_birth': '1994-02-11',
      });
      for (final dropped in const [
        'first_name',
        'last_name',
        'bio',
        'agent_id',
        'profile_image_url',
        'email',
      ]) {
        expect(body.containsKey(dropped), isFalse, reason: dropped);
      }
    });

    test('a blank phone is not sent', () async {
      final adapter = RecordingAdapter((_) => FakeReply(users['profile']));
      await UsersProvider(
        dio: fakeDio(adapter),
      ).updateProfile(fullName: 'Asha', phone: '  ');
      expect(obj(adapter.last.data).containsKey('phone'), isFalse);
    });

    test('PUT /users/location sends latitude and longitude only', () async {
      final adapter = RecordingAdapter((_) => FakeReply(users['location']));
      final location = await UsersProvider(
        dio: fakeDio(adapter),
      ).updateLocation(latitude: 15.51, longitude: 73.76);
      final body = obj(adapter.last.data);
      expectBodyMatches('LocationUpdate', body);
      expect(body.keys, unorderedEquals(['latitude', 'longitude']));
      expect(location.latitude, 15.51);
      expect(location.longitude, 73.76);
    });

    test(
      'PUT /users/notifications sends the four declared keys only',
      () async {
        final adapter = RecordingAdapter(
          (_) => FakeReply(users['notification_settings']),
        );
        final stored = await UsersProvider(dio: fakeDio(adapter))
            .updateNotificationSettings(
              pushNotifications: false,
              promotionalEmails: true,
            );
        final body = obj(adapter.last.data);
        expectBodyMatches('NotificationSettingsWrite', body);
        expect(body, {'push_notifications': false, 'promotional_emails': true});
        expect(stored['promotional_emails'], true);
      },
    );

    test('PUT /users/preferences reads the stored preferences', () async {
      final adapter = RecordingAdapter((_) => FakeReply(users['preferences']));
      final stored = await UsersProvider(
        dio: fakeDio(adapter),
      ).updatePreferences({'purpose': 'short_stay', 'budget_max': 9000.5});
      expectBodyMatches('UserPreferencesPatch', obj(adapter.last.data));
      expect(stored['purpose'], 'short_stay');
    });

    test('privacy settings go to /users/privacy-settings', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(users['privacy_settings']),
      );
      final stored = await UsersProvider(
        dio: fakeDio(adapter),
      ).updatePrivacySettings({'profile_visibility': 'private'});
      expect(adapter.last.path, '/api/v1/users/privacy-settings');
      expectBodyMatches('PrivacySettingsPatch', obj(adapter.last.data));
      expect(stored['profile_visibility'], 'private');
    });

    test('POST /notifications/devices/register sends app_key stays', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(fixture('notifications')['registration'], status: 201),
      );
      await UsersProvider(dio: fakeDio(adapter)).registerDeviceToken(
        token: 'fcm-token',
        platform: DevicePlatform.ios,
        appVersion: '1.0.1+2',
        locale: 'en-IN',
      );
      final body = obj(adapter.last.data);
      expectBodyMatches('DeviceRegisterIn', body);
      expect(body['app_key'], 'stays');
      expect(body['platform'], 'ios');
      expect(body.containsKey('user_id'), isFalse);
    });

    test(
      'DELETE /notifications/devices/unregister sends the token in a JSON body',
      () async {
        final adapter = RecordingAdapter(
          (_) => const FakeReply(null, status: 204),
        );
        await UsersProvider(
          dio: fakeDio(adapter),
        ).unregisterDeviceToken('fcm-token');
        expect(adapter.last.method, 'DELETE');
        expect(adapter.last.path, '/api/v1/notifications/devices/unregister');
        // The token never goes in the URL: the route reads a JSON body.
        expect(adapter.last.uri.query, isEmpty);
        final body = obj(adapter.last.data);
        expectBodyMatches('DeviceUnregisterIn', body);
        expect(body['token'], 'fcm-token');
      },
    );
  });

  group('auth', () {
    test('POST /auth/identifier-status parses channel and next_step', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(auth['identifier_status']),
      );
      final status = await AuthApiProvider(
        dio: fakeDio(adapter),
      ).identifierStatus('+919800000000');
      expectBodyMatches('IdentifierStatusRequest', obj(adapter.last.data));
      expect(status.channel, IdentifierChannel.phone);
      expect(status.nextStep, IdentifierNextStep.otp);
      expect(status.isOtpStep, isTrue);
    });

    test(
      'GET /users/me/auth-state sends app=stays and reads the gate',
      () async {
        final adapter = RecordingAdapter((_) => FakeReply(auth['auth_state']));
        final gate = await AuthApiProvider(
          dio: fakeDio(adapter),
        ).getAuthGateState();
        expect(queryOf(adapter.last)['app'], ['stays']);
        expect(gate.stage, AuthGateStage.appOnboarding);
        expect(gate.nextAction, AuthGateAction.completeOnboarding);
        expect(gate.missingFields, isEmpty);
      },
    );

    test('POST /users/me/onboarding sends app=stays', () async {
      final adapter = RecordingAdapter((_) => FakeReply(users['profile']));
      final ok = await AuthApiProvider(
        dio: fakeDio(adapter),
      ).completeOnboarding();
      expect(ok, isTrue);
      expect(queryOf(adapter.last)['app'], ['stays']);
    });

    test('account deletion is DELETE /users/me and answers 204', () async {
      final adapter = RecordingAdapter(
        (_) => const FakeReply(null, status: 204),
      );
      await AuthApiProvider(dio: fakeDio(adapter)).deleteAccount();
      expect(adapter.last.method, 'DELETE');
      expect(adapter.last.path, '/api/v1/users/me');
    });
  });

  group('bug reports', () {
    test('title, description and app_version stay inside the limits', () {
      final body = BugReportRequest(
        bugType: BugType.crash,
        title: '  ${'t' * 250}  ',
        description: '  It crashes.  ',
        appVersion: 'v' * 80,
      ).toMap();
      expect((body['title'] as String).length, 200);
      expect(body['description'], 'It crashes.');
      expect((body['app_version'] as String).length, 50);
      expectBodyMatches('BugReportCreate', body);
    });

    test('a title of emoji is counted in characters, not code units', () {
      final body = BugReportRequest(
        bugType: BugType.crash,
        title: '\u{1F600}' * 250,
        description: 'x',
      ).toMap();
      expect((body['title'] as String).runes.length, 200);
    });

    test('an empty title or description is refused before the request', () {
      for (final request in const [
        BugReportRequest(bugType: BugType.crash, title: ' ', description: 'x'),
        BugReportRequest(bugType: BugType.crash, title: 'x', description: ''),
      ]) {
        expect(request.toMap, throwsA(isA<ValidationException>()));
      }
    });
  });
}
