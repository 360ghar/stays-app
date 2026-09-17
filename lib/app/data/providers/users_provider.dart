import 'dart:io';

import 'package:get/get.dart';

import '../../utils/exceptions/app_exceptions.dart';
import '../../utils/helpers/json_helpers.dart';
import '../models/user_model.dart';
import 'base_provider.dart';

class UsersProvider extends BaseProvider {
  Future<UserModel> getProfile() async {
    final response = await get('/api/v1/users/profile');
    return handleResponse(response, _parseUser);
  }

  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? fullName,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? avatarUrl,
    String? agentId,
  }) async {
    final payload = <String, dynamic>{};

    if (firstName != null) payload['first_name'] = firstName.trim();
    if (lastName != null) payload['last_name'] = lastName.trim();

    final trimmedFull = (fullName ?? '').trim();
    if (trimmedFull.isNotEmpty) {
      payload['full_name'] = trimmedFull;
    } else {
      final parts = <String>[(firstName ?? '').trim(), (lastName ?? '').trim()]
        ..removeWhere((value) => value.isEmpty);
      if (parts.isNotEmpty) {
        payload['full_name'] = parts.join(' ');
      }
    }

    if (bio != null) payload['bio'] = bio;
    if (phone != null) payload['phone'] = phone;
    if (dateOfBirth != null) {
      payload['date_of_birth'] = JsonHelpers.toDateOnly(dateOfBirth);
    }
    if (avatarUrl != null) payload['profile_image_url'] = avatarUrl;
    if (agentId != null) payload['agent_id'] = agentId;

    final response = await put('/api/v1/users/profile', payload);
    return handleResponse(response, _parseUser);
  }

  Future<UserModel> updatePreferences(Map<String, dynamic> preferences) async {
    final response = await put('/api/v1/users/preferences', preferences);
    return handleResponse(response, _parseUser);
  }

  Future<UserModel> updateNotificationSettings(
    Map<String, dynamic> settings,
  ) async {
    final response = await put('/api/v1/users/notifications', settings);
    return handleResponse(response, _parseUser);
  }

  Future<UserModel> updatePrivacySettings(Map<String, dynamic> settings) async {
    final response = await put('/api/v1/users/privacy', settings);
    return handleResponse(response, _parseUser);
  }

  Future<UserModel> updateLocation({
    required double latitude,
    required double longitude,
    bool shareLocation = true,
  }) async {
    final response = await put('/api/v1/users/location', {
      'latitude': latitude,
      'longitude': longitude,
      'share_location': shareLocation,
    });
    return handleResponse(response, _parseUser);
  }

  /// Multipart avatar upload matching backend `POST /api/v1/users/me/avatar`
  /// (form field `file`). Returns the new `profile_image_url`.
  Future<String> uploadAvatar(File file) async {
    final filename = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'avatar.jpg';

    // GetConnect FormData sets multipart Content-Type + boundary itself.
    final form = FormData({
      'file': MultipartFile(file.path, filename: filename),
    });

    final response = await post('/api/v1/users/me/avatar', form);
    return handleResponse(response, (body) {
      if (body is Map) {
        final map = Map<String, dynamic>.from(body);
        final data = map['data'] is Map
            ? Map<String, dynamic>.from(map['data'] as Map)
            : map;
        final url =
            data['profile_image_url'] ??
            data['avatar_url'] ??
            data['url'] ??
            map['profile_image_url'] ??
            map['url'];
        if (url is String && url.isNotEmpty) return url;
      }
      if (body is String && body.isNotEmpty) return body;
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

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? appVersion,
    String? locale,
  }) async {
    final payload = <String, dynamic>{
      'token': token,
      'platform': platform,
      'app_version': ?appVersion,
      'locale': ?locale,
    };
    final response = await post(
      '/api/v1/notifications/devices/register',
      payload,
    );
    if (!response.isOk) {
      throw ApiException(
        message: response.statusText ?? 'Failed to register device token',
        statusCode: response.statusCode ?? 500,
      );
    }
  }

  UserModel _parseUser(dynamic body) {
    if (body == null) {
      throw ApiException(
        message: 'Empty response body received',
        statusCode: 500,
      );
    }
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return UserModel.fromJson(Map<String, dynamic>.from(data));
      }
      return UserModel.fromJson(Map<String, dynamic>.from(body));
    }
    throw ApiException(
      message: 'Invalid user payload received',
      statusCode: 500,
    );
  }
}
