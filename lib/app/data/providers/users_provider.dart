import 'dart:convert';
import 'dart:io';

import '../../utils/exceptions/app_exceptions.dart';
import '../models/user_model.dart';
import 'base_provider.dart';

class UsersProvider extends BaseProvider {
  Future<UserModel> getProfile() async {
    final response = await get('/api/v1/users/profile/');
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
      payload['date_of_birth'] = dateOfBirth.toIso8601String();
    }
    if (avatarUrl != null) payload['profile_image_url'] = avatarUrl;
    if (agentId != null) payload['agent_id'] = agentId;

    final response = await put('/api/v1/users/profile/', payload);
    return handleResponse(response, _parseUser);
  }

  Future<UserModel> updatePreferences(Map<String, dynamic> preferences) async {
    final response = await put('/api/v1/users/preferences/', preferences);
    return handleResponse(response, _parseUser);
  }

  Future<UserModel> updateNotificationSettings(
    Map<String, dynamic> settings,
  ) async {
    final response = await put('/api/v1/users/notifications/', settings);
    return handleResponse(response, _parseUser);
  }

  Future<UserModel> updatePrivacySettings(Map<String, dynamic> settings) async {
    final response = await put('/api/v1/users/privacy/', settings);
    return handleResponse(response, _parseUser);
  }

  Future<UserModel> updateLocation({
    required double latitude,
    required double longitude,
    bool shareLocation = true,
  }) async {
    final response = await put('/api/v1/users/location/', {
      'latitude': latitude,
      'longitude': longitude,
      'share_location': shareLocation,
    });
    return handleResponse(response, _parseUser);
  }

  Future<String> uploadAvatar(File file) async {
    final filename =
        file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'avatar.jpg';

    final bytes = await file.readAsBytes();
    final payload = {'filename': filename, 'file_base64': base64Encode(bytes)};

    final response = await post('/api/v1/users/profile/avatar/', payload);
    return handleResponse(response, (body) {
      if (body is Map<String, dynamic>) {
        if (body['url'] is String) return body['url'] as String;
        final data = body['data'];
        if (data is Map<String, dynamic> && data['url'] is String) {
          return data['url'] as String;
        }
      }
      if (body is String) {
        return body;
      }
      return '';
    });
  }

  Future<void> requestDataExport() async {
    final response = await post('/api/v1/users/export/', {});
    if (!response.isOk) {
      throw ApiException(
        message: response.statusText ?? 'Failed to request data export',
        statusCode: response.statusCode ?? 500,
      );
    }
  }

  Future<void> deleteAccount() async {
    final response = await delete('/api/v1/users/account/');
    if (!response.isOk) {
      throw ApiException(
        message: response.statusText ?? 'Failed to delete account',
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
