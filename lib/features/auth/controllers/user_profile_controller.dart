import 'package:get/get.dart';

import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/data/providers/users_provider.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/data/services/storage_service.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';

/// Controller responsible for user profile management.
/// Handles profile fetching, updating, and caching.
class UserProfileController extends BaseController {
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  ProfileRepository? _profileRepository;

  UserProfileController();

  /// Get the current user's display name
  String get displayName => currentUser.value?.displayName ?? 'Guest';

  /// Get the current user's initials
  String get initials => currentUser.value?.initials ?? 'GU';

  /// Check if user has a profile image
  bool get hasProfileImage => currentUser.value?.hasProfileImage ?? false;

  /// Get the user's avatar URL
  String? get avatarUrl => currentUser.value?.effectiveAvatarUrl;

  /// Fetch latest profile from API, update observable and cache for fast prefill
  Future<UserModel?> fetchAndCacheProfile() async {
    try {
      final repo = _ensureProfileRepository();
      final profile = await repo.getProfile();
      currentUser.value = profile;
      await _cacheUserData(profile);
      AppLogger.info('Profile refreshed for ${profile.email ?? profile.phone}');
      return profile;
    } catch (e) {
      AppLogger.warning('Failed to refresh user profile: $e');
      return null;
    }
  }

  /// Load cached user data from storage
  Future<void> loadCachedUser() async {
    try {
      if (Get.isRegistered<StorageService>()) {
        final storage = Get.find<StorageService>();
        final userData = await storage.getUserData();
        if (userData != null) {
          currentUser.value = UserModel.fromMap(userData);
          AppLogger.info(
            'Loaded cached user: ${currentUser.value?.displayName}',
          );
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to load cached user: $e');
    }
  }

  /// Update user profile data
  Future<UserModel?> updateProfile({
    String? firstName,
    String? lastName,
    String? fullName,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? avatarUrl,
    String? agentId,
  }) async {
    try {
      isLoading.value = true;
      final repo = _ensureProfileRepository();
      final updated = await repo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        fullName: fullName,
        bio: bio,
        phone: phone,
        dateOfBirth: dateOfBirth,
        avatarUrl: avatarUrl,
        agentId: agentId,
      );
      currentUser.value = updated;
      await _cacheUserData(updated);
      return updated;
    } catch (e, stack) {
      AppLogger.error('Failed to update user profile', e, stack);
      handleError(e, stack);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update user preferences
  Future<UserModel?> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      isLoading.value = true;
      final repo = _ensureProfileRepository();
      final updated = await repo.updatePreferences(preferences);
      currentUser.value = updated;
      await _cacheUserData(updated);
      return updated;
    } catch (e, stack) {
      AppLogger.error('Failed to update user preferences', e, stack);
      handleError(e, stack);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update user location
  Future<UserModel?> updateLocation({
    required double latitude,
    required double longitude,
    bool shareLocation = true,
  }) async {
    try {
      isLoading.value = true;
      final repo = _ensureProfileRepository();
      final updated = await repo.updateLocation(
        latitude: latitude,
        longitude: longitude,
        shareLocation: shareLocation,
      );
      currentUser.value = updated;
      await _cacheUserData(updated);
      return updated;
    } catch (e, stack) {
      AppLogger.error('Failed to update user location', e, stack);
      handleError(e, stack);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear user data (on logout)
  Future<void> clearUser() async {
    currentUser.value = null;
    try {
      if (Get.isRegistered<StorageService>()) {
        await Get.find<StorageService>().clearUserData();
      }
    } catch (e) {
      AppLogger.warning('Failed to clear user data: $e');
    }
  }

  /// Set the current user directly (e.g., after login)
  void setUser(UserModel user) {
    currentUser.value = user;
  }

  ProfileRepository _ensureProfileRepository() {
    if (_profileRepository != null) {
      return _profileRepository!;
    }
    if (Get.isRegistered<ProfileRepository>()) {
      _profileRepository = Get.find<ProfileRepository>();
      return _profileRepository!;
    }
    if (!Get.isRegistered<UsersProvider>()) {
      Get.put<UsersProvider>(UsersProvider());
    }
    _profileRepository = ProfileRepository(provider: Get.find<UsersProvider>());
    Get.put<ProfileRepository>(_profileRepository!);
    return _profileRepository!;
  }

  Future<void> _cacheUserData(UserModel user) async {
    try {
      if (Get.isRegistered<StorageService>()) {
        final storage = Get.find<StorageService>();
        await storage.saveUserData(user.toMap());
      }
    } catch (e) {
      AppLogger.warning('Failed to cache user data: $e');
    }
  }
}
