import 'dart:io';

import '../models/user_model.dart';
import '../providers/users_provider.dart';

class ProfileRepository {
  ProfileRepository({required UsersProvider provider}) : _provider = provider;

  final UsersProvider _provider;

  Future<UserModel> getProfile() => _provider.getProfile();

  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
  }) {
    return _provider.updateProfile(
      fullName: fullName,
      phone: phone,
      dateOfBirth: dateOfBirth,
    );
  }

  Future<Map<String, dynamic>> updatePreferences(
    Map<String, dynamic> preferences,
  ) {
    return _provider.updatePreferences(preferences);
  }

  Future<Map<String, dynamic>> updateNotificationSettings({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? promotionalEmails,
  }) {
    return _provider.updateNotificationSettings(
      pushNotifications: pushNotifications,
      emailNotifications: emailNotifications,
      smsNotifications: smsNotifications,
      promotionalEmails: promotionalEmails,
    );
  }

  Future<Map<String, dynamic>> updatePrivacySettings(
    Map<String, dynamic> settings,
  ) {
    return _provider.updatePrivacySettings(settings);
  }

  Future<UserLocation> updateLocation({
    required double latitude,
    required double longitude,
  }) {
    return _provider.updateLocation(latitude: latitude, longitude: longitude);
  }

  Future<String> uploadAvatar(File file) => _provider.uploadAvatar(file);

  /// Not supported by backend (`POST /users/export/` does not exist).
  Future<void> requestDataExport() => _provider.requestDataExport();
}
