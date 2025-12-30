import 'dart:io';

import '../models/user_model.dart';
import '../providers/users_provider.dart';

class ProfileRepository {
  ProfileRepository({required UsersProvider provider}) : _provider = provider;

  final UsersProvider _provider;

  Future<UserModel> getProfile() => _provider.getProfile();

  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? fullName,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? avatarUrl,
    String? agentId,
  }) {
    return _provider.updateProfile(
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      bio: bio,
      phone: phone,
      dateOfBirth: dateOfBirth,
      avatarUrl: avatarUrl,
      agentId: agentId,
    );
  }

  Future<UserModel> updatePreferences(Map<String, dynamic> preferences) {
    return _provider.updatePreferences(preferences);
  }

  Future<UserModel> updateNotificationSettings(Map<String, dynamic> settings) {
    return _provider.updateNotificationSettings(settings);
  }

  Future<UserModel> updatePrivacySettings(Map<String, dynamic> settings) {
    return _provider.updatePrivacySettings(settings);
  }

  Future<UserModel> updateLocation({
    required double latitude,
    required double longitude,
    bool shareLocation = true,
  }) {
    return _provider.updateLocation(
      latitude: latitude,
      longitude: longitude,
      shareLocation: shareLocation,
    );
  }

  Future<String> uploadAvatar(File file) => _provider.uploadAvatar(file);

  Future<void> requestDataExport() => _provider.requestDataExport();

  Future<void> deleteAccount() => _provider.deleteAccount();
}
