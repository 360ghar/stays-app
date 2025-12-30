import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/features/trips/controllers/trips_controller.dart';
import 'package:stays_app/app/data/models/trip_model.dart';
import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class ProfileController extends GetxController {
  ProfileController({
    required ProfileRepository profileRepository,
    required AuthController authController,
  }) : _profileRepository = profileRepository,
       _authController = authController;

  final ProfileRepository _profileRepository;
  final AuthController _authController;

  final Rxn<UserModel> user = Rxn<UserModel>();
  final RxString displayName = ''.obs;
  final RxString initials = ''.obs;
  final RxString email = ''.obs;
  final RxString phone = ''.obs;
  final RxString roleLabel = 'Guest'.obs;
  final RxnString avatarUrl = RxnString();
  final Rx<DateTime?> memberSince = Rx<DateTime?>(null);

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isActionInProgress = false.obs;
  final RxString errorMessage = ''.obs;

  final RxDouble completion = 0.0.obs;
  final RxList<TripModel> pastTrips = <TripModel>[].obs;
  final RxInt totalTrips = 0.obs;
  final RxInt totalNights = 0.obs;
  final RxDouble totalSpent = 0.0.obs;
  final RxString favoriteDestination = ''.obs;

  final RxMap<String, dynamic> preferences = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> notificationSettings = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> privacySettings = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _hydrateFromAuth();
    loadProfile();
  }

  void _hydrateFromAuth() {
    final current = _authController.currentUser.value;
    if (current != null) {
      _applyUser(current);
    }
  }

  Future<void> loadProfile({bool forceRefresh = false}) async {
    if (isLoading.value && !forceRefresh) return;
    try {
      if (forceRefresh) {
        isRefreshing.value = true;
      } else {
        isLoading.value = true;
      }
      final profile = await _profileRepository.getProfile();
      _authController.currentUser.value = profile;
      _applyUser(profile);
      await _loadPastTrips();
    } catch (e, stack) {
      AppLogger.error('Failed to load profile', e, stack);
      errorMessage.value = 'Failed to load your profile. Please try again.';
      Get.snackbar(
        'Profile',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshProfile() => loadProfile(forceRefresh: true);

  void _applyUser(UserModel profile) {
    user.value = profile;
    displayName.value = profile.displayName;
    initials.value = profile.initials;
    email.value = profile.email ?? '';
    phone.value = profile.phone ?? '';
    roleLabel.value = profile.isSuperHost ? 'Superhost' : 'Guest';
    avatarUrl.value = profile.effectiveAvatarUrl;
    memberSince.value = profile.createdAt;
    preferences.assignAll(profile.preferences ?? {});
    notificationSettings.assignAll(profile.notificationSettings ?? {});
    privacySettings.assignAll(profile.privacySettings ?? {});
    completion.value = _calculateCompletion(profile);
  }

  double _calculateCompletion(UserModel profile) {
    final checks = <bool>[
      profile.displayName.trim().isNotEmpty,
      (profile.email ?? '').trim().isNotEmpty,
      (profile.phone ?? '').trim().isNotEmpty,
      profile.dateOfBirth != null,
      profile.hasProfileImage,
      (profile.bio ?? '').trim().isNotEmpty,
      (preferences['language'] ?? '').toString().isNotEmpty,
      (preferences['theme'] ?? '').toString().isNotEmpty,
      (notificationSettings['push'] ?? false) ||
          (notificationSettings['email'] ?? false),
      (privacySettings['twoFactorEnabled'] ?? false) ||
          (privacySettings['profileVisible'] ?? true),
    ];
    final completed = checks.where((value) => value).length;
    return checks.isEmpty ? 0 : completed / checks.length;
  }

  Future<void> _loadPastTrips() async {
    try {
      if (Get.isRegistered<TripsController>()) {
        final tripsController = Get.find<TripsController>();
        await tripsController.loadPastBookings();
        if (tripsController.pastBookings.isNotEmpty) {
          pastTrips.assignAll(
            tripsController.pastBookings.map(_mapBookingToTrip),
          );
        } else {
          pastTrips.clear();
        }
      } else {
        pastTrips.clear();
      }
    } catch (e) {
      AppLogger.warning('Unable to load past trips from TripsController', e);
    } finally {
      _recalculateTripStats();
    }
  }

  TripModel _mapBookingToTrip(Map<String, dynamic> booking) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return TripModel(
      id: booking['id']?.toString() ?? UniqueKey().hashCode.toString(),
      propertyName:
          booking['hotelName']?.toString() ??
          booking['propertyName']?.toString() ??
          'Stay',
      checkIn: parseDate(
        booking['checkIn'] ?? booking['check_in'] ?? booking['checkInDate'],
      ),
      checkOut: parseDate(
        booking['checkOut'] ?? booking['check_out'] ?? booking['checkOutDate'],
      ),
      status: booking['status']?.toString() ?? 'completed',
      propertyImage: booking['image']?.toString(),
      totalCost: (booking['totalAmount'] as num?)?.toDouble(),
      hostName: booking['hostName']?.toString(),
    );
  }

  void _recalculateTripStats() {
    totalTrips.value = pastTrips.length;
    if (pastTrips.isEmpty) {
      totalNights.value = 0;
      totalSpent.value = 0;
      favoriteDestination.value = 'Plan your next stay';
      return;
    }

    var nights = 0;
    var spend = 0.0;
    final destinations = <String, int>{};
    for (final trip in pastTrips) {
      final diff = trip.checkOut.difference(trip.checkIn).inDays;
      nights += max(diff, 1);
      if (_shouldIncludeInSpend(trip.status)) {
        spend += trip.totalCost ?? 0;
      }
      final key = trip.propertyName;
      destinations[key] = (destinations[key] ?? 0) + 1;
    }
    totalNights.value = nights;
    totalSpent.value = spend;
    favoriteDestination.value = destinations.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  bool _shouldIncludeInSpend(String? status) {
    if (status == null) return false;
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    const negativeKeywords = [
      'cancel',
      'refund',
      'fail',
      'decline',
      'reject',
      'void',
      'expired',
    ];
    if (negativeKeywords.any((keyword) => normalized.contains(keyword))) {
      return false;
    }
    return true;
  }

  void updateUser(UserModel updated) {
    _authController.currentUser.value = updated;
    _applyUser(updated);
  }

  void updateAvatarLocal(String url) {
    final current = user.value;
    if (current == null) return;
    final updated = current.copyWith(
      avatarUrl: url,
      profileImageUrl: url,
      updatedAt: DateTime.now(),
    );
    updateUser(updated);
  }

  void updatePreferencesLocal(Map<String, dynamic> updatedPrefs) {
    preferences.assignAll(updatedPrefs);
    final current = user.value;
    if (current != null) {
      updateUser(current.copyWith(preferences: {...preferences}));
    }
  }

  void updateNotificationSettingsLocal(Map<String, dynamic> settings) {
    notificationSettings.assignAll(settings);
    final current = user.value;
    if (current != null) {
      updateUser(
        current.copyWith(notificationSettings: {...notificationSettings}),
      );
    }
  }

  void updatePrivacySettingsLocal(Map<String, dynamic> settings) {
    privacySettings.assignAll(settings);
    final current = user.value;
    if (current != null) {
      updateUser(current.copyWith(privacySettings: {...privacySettings}));
    }
  }

  void navigateToEditProfile() => Get.toNamed(Routes.editProfile);

  void navigateToPreferences() => Get.toNamed(Routes.profilePreferences);

  void navigateToNotifications() => Get.toNamed(Routes.profileNotifications);

  void navigateToPrivacy() => Get.toNamed(Routes.profilePrivacy);

  void navigateToHelp() => Get.toNamed(Routes.profileHelp);

  void navigateToAbout() => Get.toNamed(Routes.profileAbout);

  void navigateToInquiries() => Get.toNamed(Routes.inquiries);
  // Backwards-compatible alias
  void navigateToEnquiries() => navigateToInquiries();

  Future<void> confirmLogout() async {
    final shouldLogout =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Log out'),
            content: const Text(
              'You will be signed out of your account. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldLogout) {
      await logout();
    }
  }

  Future<void> logout() async {
    if (isActionInProgress.value) return;
    try {
      isActionInProgress.value = true;
      await _authController.logout();
      user.value = null;
      Get.offAllNamed(Routes.login);
      Get.snackbar(
        'Signed out',
        'You have been logged out safely.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stack) {
      AppLogger.error('Logout failed', e, stack);
      Get.snackbar(
        'Logout failed',
        'Please try again in a moment.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isActionInProgress.value = false;
    }
  }
}
