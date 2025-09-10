import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/user_model.dart';
import '../../data/models/trip_model.dart';
import '../../routes/app_routes.dart';
import 'phone_auth_controller.dart';

class ProfileController extends GetxController {
  final Rx<UserModel?> profile = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxList<TripModel> pastTrips = <TripModel>[].obs;
  final RxString userInitials = ''.obs;
  final RxString userName = 'Guest User'.obs;
  final RxString userType = 'Guest'.obs;
  final RxString userPhone = ''.obs;
  
  late final PhoneAuthController _authController;

  @override
  void onInit() {
    super.onInit();
    _authController = Get.find<PhoneAuthController>();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      isLoading.value = true;
      
      // Get user data from existing auth controller
      profile.value = _authController.currentUser.value;
      
      if (profile.value != null) {
        _updateUserInfo(profile.value!);
      } else {
        // Set default guest user if no user data
        userName.value = 'Guest User';
        userInitials.value = 'GU';
        userType.value = 'Guest';
        userPhone.value = '';
      }
      
      // Load past trips
      await _loadPastTrips();
      
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
    final firstName = user.firstName ?? '';
    final lastName = user.lastName ?? '';
    
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      userName.value = '$firstName $lastName'.trim();
      userInitials.value = _generateInitials(firstName, lastName);
    } else {
      userName.value = user.phone ?? 'User';
      userInitials.value = userName.value.substring(0, 1).toUpperCase();
    }
    
    userPhone.value = user.phone ?? '';
    userType.value = user.isSuperHost ? 'Superhost' : 'Guest';
  }

  String _generateInitials(String firstName, String lastName) {
    String initials = '';
    if (firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }
    if (initials.isEmpty && userPhone.value.isNotEmpty) {
      initials = userPhone.value[0].toUpperCase();
    }
    return initials;
  }

  Future<void> _loadPastTrips() async {
    // Mock past trips data - replace with actual API call
    pastTrips.value = [
      TripModel(
        id: '1',
        propertyName: 'Cozy Apartment in Downtown',
        checkIn: DateTime.now().subtract(const Duration(days: 30)),
        checkOut: DateTime.now().subtract(const Duration(days: 27)),
        status: 'completed',
      ),
      TripModel(
        id: '2',
        propertyName: 'Beach House Paradise',
        checkIn: DateTime.now().subtract(const Duration(days: 60)),
        checkOut: DateTime.now().subtract(const Duration(days: 55)),
        status: 'completed',
      ),
    ];
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

