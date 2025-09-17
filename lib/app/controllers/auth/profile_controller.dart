import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/user_model.dart';
import '../../data/models/trip_model.dart';
import '../../routes/app_routes.dart';
import 'auth_controller.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';

class ProfileController extends GetxController {
  final Rx<UserModel?> profile = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxList<TripModel> pastTrips = <TripModel>[].obs;
  final RxString userInitials = ''.obs;
  final RxString userName = 'Guest User'.obs;
  final RxString userType = 'Guest'.obs;
  final RxString userPhone = ''.obs;

  late final AuthController _authController;

  @override
  void onInit() {
    super.onInit();
    // Ensure AuthController is available and assign exactly once
    try {
      if (Get.isRegistered<AuthController>()) {
        _authController = Get.find<AuthController>();
      } else {
        // Register dependencies if missing, then create AuthController
        if (!Get.isRegistered<AuthRepository>()) {
          Get.put<AuthRepository>(AuthRepository(), permanent: true);
        }
        _authController = Get.put<AuthController>(
          AuthController(authRepository: Get.find<AuthRepository>()),
          permanent: true,
        );
      }
    } catch (_) {
      // Keep UI graceful; errors will surface via usage
      rethrow;
    }
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      isLoading.value = true;

      // Get user data from existing auth controller
      profile.value = _authController.currentUser.value;

      // Refresh profile from backend when authenticated
      try {
        final repo = Get.find<ProfileRepository>();
        final serverUser = await repo.getProfile();
        profile.value = serverUser;
      } catch (_) {}

      if (profile.value != null) {
        _updateUserInfo(profile.value!);
      } else {
        // Set default guest user if no user data
        userName.value = 'Guest User';
        userInitials.value = 'GU';
        userType.value = 'Guest';
        userPhone.value = '';
      }

      // Defer past trips loading to Trips screen to avoid unnecessary API calls
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load profile data',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _updateUserInfo(UserModel user) {
    final firstName = (user.firstName ?? '').trim();
    final lastName = (user.lastName ?? '').trim();
    final fullName = (user.name ?? '').trim();

    // Prefer explicit first/last; then full_name; then email/phone
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      userName.value = '$firstName $lastName'.trim();
    } else if (fullName.isNotEmpty) {
      userName.value = fullName;
    } else if ((user.email ?? '').isNotEmpty) {
      userName.value = user.email!;
    } else {
      userName.value = user.phone ?? 'User';
    }

    userInitials.value = _generateInitials(
      firstName,
      lastName,
      fallbackName: userName.value,
    );
    userPhone.value = user.phone ?? '';
    userType.value = user.isSuperHost ? 'Superhost' : 'Guest';
  }

  String _generateInitials(
    String firstName,
    String lastName, {
    required String fallbackName,
  }) {
    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0].toUpperCase();
    if (lastName.isNotEmpty) initials += lastName[0].toUpperCase();

    // If first/last not available, try splitting fallback name (e.g., full_name)
    if (initials.isEmpty && fallbackName.trim().isNotEmpty) {
      final parts = fallbackName
          .trim()
          .split(RegExp(r"\s+"))
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        initials += parts.first[0].toUpperCase();
        if (parts.length > 1) initials += parts[1][0].toUpperCase();
      }
    }

    if (initials.isEmpty && userPhone.value.isNotEmpty) {
      initials = userPhone.value[0].toUpperCase();
    }
    return initials;
  }

  void navigateToPastTrips() {
    Get.toNamed(Routes.trips);
  }

  void navigateToAccountSettings() {
    Get.toNamed(Routes.accountSettings);
  }

  void navigateToHelp() {
    Get.toNamed(Routes.help);
  }

  void navigateToViewProfile() {
    Get.toNamed(Routes.profileView);
  }

  void navigateToPrivacy() {
    Get.toNamed(Routes.privacy);
  }

  void navigateToLegal() {
    Get.toNamed(Routes.legal);
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;

      Get.dialog(
        AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Get.back();
                await _performLogout();
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _performLogout() async {
    try {
      isLoading.value = true;

      // Clear user data
      profile.value = null;
      pastTrips.clear();
      userInitials.value = '';
      userName.value = 'Guest User';
      userType.value = 'Guest';
      userPhone.value = '';

      // Call auth controller logout
      await _authController.logout();

      // Navigate to login
      Get.offAllNamed(Routes.login);

      Get.snackbar(
        'Success',
        'Logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
