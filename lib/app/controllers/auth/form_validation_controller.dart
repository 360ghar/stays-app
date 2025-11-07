import 'package:get/get.dart';

/// Centralized validation and error state for auth-related forms.
class FormValidationController extends GetxController {
  final RxString emailOrPhoneError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString confirmPasswordError = ''.obs;

  String? validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or phone is required';
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

  void clearErrors() {
    emailOrPhoneError.value = '';
    passwordError.value = '';
    confirmPasswordError.value = '';
  }
}

