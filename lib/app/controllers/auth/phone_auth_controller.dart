import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';

class PhoneAuthController extends GetxController {
  final StorageService _storageService;

  PhoneAuthController({required StorageService storageService})
      : _storageService = storageService;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;

  // Dummy credentials
  static const String validPhone = '9876543210';
  static const String validPassword = 'ravi123';

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storageService.getAccessToken();
      if (token != null) {
        isAuthenticated.value = true;
        // In a real app, fetch user profile here
        currentUser.value = UserModel(
          id: '1',
          email: 'user@example.com',
          firstName: 'Ravi',
          lastName: 'User',
        );
      }
    } catch (e) {
      debugPrint('Auth check failed: $e');
    }
  }

  Future<void> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // Check dummy credentials
      if (phone == validPhone && password == validPassword) {
        // Create mock user
        final mockUser = UserModel(
          id: '1',
          email: '+91$phone@stays.app',
          firstName: 'Ravi',
          lastName: 'User',
        );

        // Save mock tokens
        await _storageService.saveTokens(
          accessToken: 'mock_phone_token_123',
          refreshToken: 'mock_refresh_token_456',
        );

        currentUser.value = mockUser;
        isAuthenticated.value = true;

        // Success snackbar
        Get.snackbar(
          'Welcome!',
          'Successfully logged in',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade800,
          snackPosition: SnackPosition.TOP,
          borderRadius: 8,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
          icon: Container(
            margin: const EdgeInsets.only(left: 12),
            child: Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
            ),
          ),
        );

        // Navigate to home
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(Routes.home);
      } else {
        // Error snackbar for wrong credentials
        Get.snackbar(
          'Login Failed',
          'Invalid phone number or password',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
          snackPosition: SnackPosition.TOP,
          borderRadius: 8,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          icon: Container(
            margin: const EdgeInsets.only(left: 12),
            child: Icon(
              Icons.error_outline,
              color: Colors.red.shade600,
            ),
          ),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.TOP,
        borderRadius: 8,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _storageService.clearTokens();
      currentUser.value = null;
      isAuthenticated.value = false;
      Get.offAllNamed(Routes.login);
    } catch (e) {
      debugPrint('Logout failed: $e');
    }
  }
}