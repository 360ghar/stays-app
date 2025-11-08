import 'package:get/get.dart';

import '../../utils/services/validation_service.dart';

/// Enhanced form validation controller using centralized ValidationService.
/// Provides backward compatibility while leveraging improved validation.
class FormValidationController extends GetxController {
  late final ValidationService _validationService;

  // Field keys for validation
  static const String emailOrPhoneKey = 'emailOrPhone';
  static const String passwordKey = 'password';
  static const String confirmPasswordKey = 'confirmPassword';

  // Backwards-compatible reactive strings
  final RxString emailOrPhoneError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString confirmPasswordError = ''.obs;

  // Track if validators are registered
  bool _validatorsRegistered = false;

  @override
  void onInit() {
    super.onInit();
    _validationService = Get.find<ValidationService>();
    _registerValidators();
  }

  /// Register validation rules for all fields
  void _registerValidators() {
    if (_validatorsRegistered) return;

    _validationService.registerValidator(
      emailOrPhoneKey,
      ValidationService.emailOrPhoneRequired,
    );
    _validationService.registerValidator(
      passwordKey,
      ValidationService.passwordRequired,
    );

    _validatorsRegistered = true;
  }

  /// Register password confirmation validator
  void registerPasswordConfirmation(String password) {
    _validationService.registerValidator(
      confirmPasswordKey,
      _validationService.passwordConfirmation(password),
    );
  }

  /// Validate email or phone field
  String? validateEmailOrPhone(String? value) {
    final isValid = _validationService.validateField(emailOrPhoneKey, value);
    emailOrPhoneError.value = _validationService.getFieldError(emailOrPhoneKey);
    return isValid ? null : emailOrPhoneError.value;
  }

  /// Validate password field
  String? validatePassword(String? password) {
    final isValid = _validationService.validateField(passwordKey, password);
    passwordError.value = _validationService.getFieldError(passwordKey);
    return isValid ? null : passwordError.value;
  }

  /// Validate confirm password field
  String? _lastRegisteredPassword;
  String? validateConfirmPassword(String? password, String? confirmPassword) {
    // Register confirmation validator only when the password changes
    final pwd = password ?? '';
    if (_lastRegisteredPassword != pwd) {
      registerPasswordConfirmation(pwd);
      _lastRegisteredPassword = pwd;
    }

    final isValid = _validationService.validateField(confirmPasswordKey, confirmPassword);
    confirmPasswordError.value = _validationService.getFieldError(confirmPasswordKey);
    return isValid ? null : confirmPasswordError.value;
  }

  /// Validate complete login form
  bool validateLoginForm(String? emailOrPhone, String? password) {
    final emailValid = validateEmailOrPhone(emailOrPhone) == null;
    final passwordValid = validatePassword(password) == null;
    return emailValid && passwordValid;
  }

  /// Validate complete registration form
  bool validateRegistrationForm(String? emailOrPhone, String? password, String? confirmPassword) {
    final emailValid = validateEmailOrPhone(emailOrPhone) == null;
    final passwordValid = validatePassword(password) == null;
    final confirmValid = validateConfirmPassword(password, confirmPassword) == null;
    return emailValid && passwordValid && confirmValid;
  }

  /// Clear all field errors
  void clearErrors() {
    _validationService.clearAllErrors();
    emailOrPhoneError.value = '';
    passwordError.value = '';
    confirmPasswordError.value = '';
  }

  /// Clear specific field error
  void clearFieldError(String fieldKey) {
    _validationService.clearFieldError(fieldKey);
    switch (fieldKey) {
      case emailOrPhoneKey:
        emailOrPhoneError.value = '';
        break;
      case passwordKey:
        passwordError.value = '';
        break;
      case confirmPasswordKey:
        confirmPasswordError.value = '';
        break;
    }
  }

  @override
  void onClose() {
    // Cleanup is handled by ValidationService
    super.onClose();
  }
}
