import 'dart:io';

import 'package:dio/dio.dart' show FormData, MultipartFile;

import '../../utils/exceptions/app_exceptions.dart';
import '../../utils/helpers/json_helpers.dart';
import '../models/user_model.dart';
import '../models/wire_enums.dart';
import 'base_provider.dart';

/// The saved location of the user: `{current_latitude, current_longitude}`.
typedef UserLocation = ({double? latitude, double? longitude});

class UsersProvider extends BaseProvider {
  UsersProvider({super.dio});

  Future<UserModel> getProfile() async {
    final response = await get('/api/v1/users/profile');
    return handleResponse(response, _parseUser);
  }

  /// `PUT /api/v1/users/profile`. The body accepts `full_name`, `phone`,
  /// `date_of_birth`, `current_latitude`, `current_longitude`,
  /// `notification_settings` and `privacy_settings`. It rejects any other key
  /// with 422. First name, last name, bio, agent and avatar URL are not
  /// accepted: the avatar goes through [uploadAvatar].
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
  }) async {
    final payload = <String, dynamic>{};
    final trimmedFull = (fullName ?? '').trim();
    if (trimmedFull.isNotEmpty) payload['full_name'] = trimmedFull;
    if (phone != null && phone.trim().isNotEmpty) {
      payload['phone'] = phone.trim();
    }
    if (dateOfBirth != null) {
      payload['date_of_birth'] = JsonHelpers.toDateOnly(dateOfBirth);
    }

    final response = await put('/api/v1/users/profile', payload);
    return handleResponse(response, _parseUser);
  }

  /// `PUT /api/v1/users/preferences`. The answer is the stored preferences.
  Future<Map<String, dynamic>> updatePreferences(
    Map<String, dynamic> preferences,
  ) async {
    final response = await put('/api/v1/users/preferences', preferences);
    return handleResponse(response, _asMap);
  }

  /// `PUT /api/v1/users/notifications`. The body takes only these four keys.
  /// An unsent key keeps its value. The answer is the stored settings.
  Future<Map<String, dynamic>> updateNotificationSettings({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? promotionalEmails,
  }) async {
    final response = await put('/api/v1/users/notifications', {
      'push_notifications': ?pushNotifications,
      'email_notifications': ?emailNotifications,
      'sms_notifications': ?smsNotifications,
      'promotional_emails': ?promotionalEmails,
    });
    return handleResponse(response, _asMap);
  }

  /// `PUT /api/v1/users/privacy-settings`. An unsent key keeps its value. The
  /// answer is the stored settings.
  Future<Map<String, dynamic>> updatePrivacySettings(
    Map<String, dynamic> settings,
  ) async {
    final response = await put('/api/v1/users/privacy-settings', settings);
    return handleResponse(response, _asMap);
  }

  /// `PUT /api/v1/users/location`. The body is `{latitude, longitude}` only.
  Future<UserLocation> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final response = await put('/api/v1/users/location', {
      'latitude': latitude,
      'longitude': longitude,
    });
    return handleResponse(response, (body) {
      final map = _asMap(body);
      return (
        latitude: JsonHelpers.getDouble(map['current_latitude']),
        longitude: JsonHelpers.getDouble(map['current_longitude']),
      );
    });
  }

  /// Multipart avatar upload matching backend `POST /api/v1/users/me/avatar`
  /// (form field `file`). Returns the new `profile_image_url`.
  Future<String> uploadAvatar(File file) async {
    final filename = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'avatar.jpg';

    // Dio FormData sets multipart Content-Type + boundary itself.
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: filename),
    });

    final response = await post('/api/v1/users/me/avatar', form);
    return handleResponse(response, (body) {
      final url = _asMap(body)['profile_image_url'];
      if (url is String && url.isNotEmpty) return url;
      throw ApiException(
        message: 'Avatar upload succeeded but no image URL was returned',
        statusCode: 500,
      );
    });
  }

  /// Backend has no data-export endpoint; kept so UI can surface a clear error.
  Future<void> requestDataExport() async {
    throw ApiException(
      message:
          'Data export is not supported yet. Please contact support if you need a copy of your data.',
      statusCode: 501,
    );
  }

  /// `POST /api/v1/notifications/devices/register`. The body takes `token`,
  /// `platform`, `app_key` and, optionally, `app_version` and `locale`.
  Future<void> registerDeviceToken({
    required String token,
    required DevicePlatform platform,
    String? appVersion,
    String? locale,
  }) async {
    final payload = <String, dynamic>{
      'token': token,
      'platform': platform.wire,
      'app_key': AppKey.stays.wire,
      'app_version': ?appVersion,
      'locale': ?locale,
    };
    final response = await post(
      '/api/v1/notifications/devices/register',
      payload,
    );
    handleResponse(response, (_) => null);
  }

  /// `DELETE /api/v1/notifications/devices/unregister`. The token goes in a
  /// JSON body (never in the URL). The caller must still be signed in: only
  /// the caller's own token changes. The answer is 204 with no body.
  Future<void> unregisterDeviceToken(String token) async {
    final response = await delete(
      '/api/v1/notifications/devices/unregister',
      body: {'token': token},
    );
    handleResponse(response, (_) => null);
  }

  /// The self routes answer with the user itself (`SelfUser`).
  UserModel _parseUser(dynamic body) => UserModel.fromJson(_asMap(body));

  Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map) return Map<String, dynamic>.from(body);
    throw ApiException(message: 'Invalid payload received', statusCode: 500);
  }
}
