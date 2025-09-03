import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import 'auth_controller.dart';

enum OTPType { signup, forgotPassword }

class OTPController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  
  final RxBool isLoading = false.obs;
  final RxString otpError = ''.obs;
  final RxInt countdown = 30.obs;
  final RxBool canResend = false.obs;
  
  final List<TextEditingController> otpControllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> otpFocusNodes = List.generate(4, (index) => FocusNode());
  
  late OTPType otpType;
  late String phoneNumber;
  String? signupPassword;
  
  Timer? _timer;
  
  @override
  void onInit() {
    super.onInit();
    _startCountdown();
  }
  
  @override
  void onClose() {
    _timer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    super.onClose();
  }
  
  void initializeOTP({
    required OTPType type,
    required String phone,
    String? password,
  }) {
    otpType = type;
    phoneNumber = phone;
    signupPassword = password;
  }
  
  void _startCountdown() {
    canResend.value = false;
    countdown.value = 30;
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }
  
  void onOTPChanged(int index, String value) {
    otpError.value = '';
    
    if (value.isNotEmpty) {
      if (value.length == 1) {
        // Move to next field if not the last one
        if (index < 3) {
          otpFocusNodes[index + 1].requestFocus();
        } else {
          // If last field, unfocus
          otpFocusNodes[index].unfocus();
          // Auto-verify if all fields are filled
          _autoVerifyIfComplete();
        }
      } else if (value.length > 1) {
        // Handle paste - split the value across fields
        final chars = value.split('');
        for (int i = 0; i < chars.length && (index + i) < 4; i++) {
          otpControllers[index + i].text = chars[i];
        }
        // Focus the last filled field or unfocus if complete
        final lastFilledIndex = (index + chars.length - 1).clamp(0, 3);
        if (lastFilledIndex == 3) {
          otpFocusNodes[lastFilledIndex].unfocus();
          _autoVerifyIfComplete();
        } else {
          otpFocusNodes[lastFilledIndex + 1].requestFocus();
        }
      }
    }
  }
  
  void onOTPBackspace(int index) {
    if (otpControllers[index].text.isEmpty && index > 0) {
      // Move to previous field and clear it
      otpFocusNodes[index - 1].requestFocus();
      otpControllers[index - 1].clear();
    }
  }
  
  void _autoVerifyIfComplete() {
    final otp = getEnteredOTP();
    if (otp.length == 4) {
      verifyOTP();
    }
  }
  
  String getEnteredOTP() {
    return otpControllers.map((controller) => controller.text).join();
  }
  
  void clearOTP() {
    for (var controller in otpControllers) {
      controller.clear();
    }
    otpError.value = '';
    otpFocusNodes[0].requestFocus();
  }
  
  Future<void> verifyOTP() async {
    // Add guard clause to prevent double-submits
    if (isLoading.value) return;
    
    try {
      isLoading.value = true;
      otpError.value = '';
      
      final enteredOTP = getEnteredOTP();
      
      if (enteredOTP.length != 4) {
        otpError.value = 'Please enter complete OTP';
        return;
      }
      
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Demo OTP verification
      const String validOTP = '0000';
      
      if (enteredOTP == validOTP) {
        // Handle different OTP types
        switch (otpType) {
          case OTPType.signup:
            await _handleSignupSuccess();
            break;
          case OTPType.forgotPassword:
            _handleForgotPasswordSuccess();
            break;
        }
      } else {
        otpError.value = 'Invalid OTP. Please try again';
        // Clear OTP fields
        clearOTP();
      }
    } catch (e) {
      _showErrorSnackbar('Verification failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> _handleSignupSuccess() async {
    // Complete signup process
    _showSuccessSnackbar('Account created successfully!');
    
    // Auto login after successful signup
    if (signupPassword != null) {
      await _authController.loginWithPhone(
        phone: phoneNumber.replaceAll('+91', ''),
        password: signupPassword!,
      );
    } else {
      Get.offAllNamed(Routes.login);
    }
  }
  
  void _handleForgotPasswordSuccess() {
    _showSuccessSnackbar('OTP verified successfully!');
    // Navigate to reset password screen
    Get.toNamed(Routes.resetPassword, arguments: phoneNumber);
  }
  
  Future<void> resendOTP() async {
    try {
      isLoading.value = true;
      
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      _showSuccessSnackbar('OTP sent successfully!');
      _startCountdown();
      clearOTP();
    } catch (e) {
      _showErrorSnackbar('Failed to resend OTP. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
  
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      '',
      '',
      titleText: const Text(
        'Success',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.9),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      icon: const Icon(
        Icons.check_circle_outline,
        color: Colors.white,
        size: 20,
      ),
    );
  }
  
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      '',
      '',
      titleText: const Text(
        'Error',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      backgroundColor: const Color(0xFFE91E63).withOpacity(0.9),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      icon: const Icon(
        Icons.error_outline,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}