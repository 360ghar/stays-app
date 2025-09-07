import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/storage_service.dart';
import '../../data/models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/logger/app_logger.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository;
  final StorageService _storageService;

  AuthController({required AuthRepository authRepository, required StorageService storageService})
      : _authRepository = authRepository,
        _storageService = storageService;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  final RxBool isPasswordVisible = false.obs;
  
  // Form validation observables
  final RxString phoneError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString confirmPasswordError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }
    if (phone.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return 'Phone number should contain only digits';
    }
    return null;
  }

  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storageService.getAccessToken();
      if (token != null) {
        // In a real app, fetch profile
        isAuthenticated.value = true;
      }
    } catch (e) {
      AppLogger.error('Auth check failed', e);
    }
  }

  Future<void> loginWithPhone({required String phone, required String password}) async {
    try {
      isLoading.value = true;
      
      // Clear previous errors
      phoneError.value = '';
      passwordError.value = '';
      
      // Validate inputs
      final phoneValidation = validatePhone(phone);
      final passwordValidation = validatePassword(password);
      
      if (phoneValidation != null) {
        phoneError.value = phoneValidation;
        return;
      }
      
      if (passwordValidation != null) {
        passwordError.value = passwordValidation;
        return;
      }
      
      // Dummy authentication with phone
      const String validPhone = '9876543210';
      const String validPassword = 'ravi123';
      
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (phone == validPhone && password == validPassword) {
        // Mock user data
        final mockUser = UserModel(
          id: '1',
          email: 'user@example.com',
          firstName: 'Ravi',
          lastName: 'Sahu',
        );
        
        // Save mock tokens
        await _storageService.saveTokens(
          accessToken: 'mock_access_token_123',
          refreshToken: 'mock_refresh_token_456',
        );
        
        currentUser.value = mockUser;
        isAuthenticated.value = true;
        
        _showSuccessSnackbar(
          title: 'Welcome Back!',
          message: 'Hello ${mockUser.firstName}, great to see you again!',
        );
        
        Get.offAllNamed(Routes.home);
      } else {
        _showErrorSnackbar(
          title: 'Login Failed',
          message: 'Invalid phone number or password. Please check and try again.',
        );
      }
    } catch (e) {
      _showErrorSnackbar(
        title: 'Error',
        message: 'An error occurred. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> registerWithPhone({required String phone, required String password}) async {
    try {
      isLoading.value = true;
      
      // Clear previous errors
      phoneError.value = '';
      passwordError.value = '';
      
      // Validate inputs
      final phoneValidation = validatePhone(phone);
      final passwordValidation = validatePassword(password);
      
      if (phoneValidation != null) {
        phoneError.value = phoneValidation;
        return false;
      }
      
      if (passwordValidation != null) {
        passwordError.value = passwordValidation;
        return false;
      }
      
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      return true; // Success, will proceed to OTP
    } catch (e) {
      _showErrorSnackbar(
        title: 'Error',
        message: 'Registration failed. Please try again.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> sendForgotPasswordOTP(String phone) async {
    try {
      isLoading.value = true;
      
      // Clear previous errors
      phoneError.value = '';
      
      // Validate phone
      final phoneValidation = validatePhone(phone);
      if (phoneValidation != null) {
        phoneError.value = phoneValidation;
        return false;
      }
      
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      return true; // Success, OTP sent
    } catch (e) {
      _showErrorSnackbar(
        title: 'Error',
        message: 'Failed to send OTP. Please try again.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword({required String newPassword, required String confirmPassword}) async {
    try {
      isLoading.value = true;
      
      // Clear previous errors
      passwordError.value = '';
      confirmPasswordError.value = '';
      
      // Validate passwords
      final passwordValidation = validatePassword(newPassword);
      final confirmPasswordValidation = validateConfirmPassword(newPassword, confirmPassword);
      
      if (passwordValidation != null) {
        passwordError.value = passwordValidation;
        return;
      }
      
      if (confirmPasswordValidation != null) {
        confirmPasswordError.value = confirmPasswordValidation;
        return;
      }
      
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      _showSuccessSnackbar(
        title: 'Success',
        message: 'Password reset successful!',
      );
      
      Get.offAllNamed(Routes.login);
    } catch (e) {
      _showErrorSnackbar(
        title: 'Error',
        message: 'Failed to reset password. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _showSuccessSnackbar({required String title, required String message}) {
    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.9),
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 500),
      snackPosition: SnackPosition.TOP,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _showErrorSnackbar({required String title, required String message}) {
    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      backgroundColor: const Color(0xFFE91E63).withValues(alpha: 0.9),
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 500),
      snackPosition: SnackPosition.TOP,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Future<void> login({required String email, required String password}) async {
    try {
      isLoading.value = true;
      
      // Dummy authentication
      const String validEmail = 'ravisahu@gmail.com';
      const String validPassword = 'ravi123';
      
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (email.toLowerCase() == validEmail && password == validPassword) {
        // Mock user data
        final mockUser = UserModel(
          id: '1',
          email: email,
          firstName: 'Ravi',
          lastName: 'Sahu',
        );
        
        // Save mock tokens
        await _storageService.saveTokens(
          accessToken: 'mock_access_token_123',
          refreshToken: 'mock_refresh_token_456',
        );
        
        currentUser.value = mockUser;
        isAuthenticated.value = true;
        
        _showSuccessSnackbar(
          title: 'Welcome Back!',
          message: 'Hello ${mockUser.firstName}, great to see you again!',
        );
        
        Get.offAllNamed(Routes.home);
      } else {
        _showErrorSnackbar(
          title: 'Login Failed',
          message: 'Invalid email or password. Please check and try again.',
        );
      }
    } catch (e) {
      _showErrorSnackbar(
        title: 'Error',
        message: 'An error occurred. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout(_storageService);
      await _storageService.clearTokens();
      currentUser.value = null;
      isAuthenticated.value = false;
      Get.offAllNamed(Routes.login);
    } catch (e) {
      AppLogger.error('Logout failed', e);
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 800));
      Get.snackbar('Success', 'Account created. Please login.');
      Get.offAllNamed(Routes.login);
    } catch (e) {
      Get.snackbar('Error', 'Registration failed');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 800));
      Get.snackbar('Email sent', 'Check your inbox for reset link');
    } catch (e) {
      Get.snackbar('Error', 'Failed to send reset link');
    } finally {
      isLoading.value = false;
    }
  }
}
