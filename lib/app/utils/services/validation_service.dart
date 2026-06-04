import 'package:get/get.dart';

/// Validation rule interface for different field types
abstract class ValidationRule {
  const ValidationRule();
  String? validate(String? value);
}

/// Required field validation rule
class RequiredRule extends ValidationRule {
  const RequiredRule({this.customMessage});

  final String? customMessage;

  @override
  String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return customMessage ?? 'This field is required';
    }
    return null;
  }
}

/// Email validation rule
class EmailRule extends ValidationRule {
  const EmailRule({this.customMessage});

  final String? customMessage;

  @override
  String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return customMessage ?? 'Please enter a valid email address';
    }
    return null;
  }
}

/// Phone validation rule
class PhoneRule extends ValidationRule {
  const PhoneRule({this.customMessage});

  final String? customMessage;

  @override
  String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Basic phone number validation (10-15 digits)
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return customMessage ?? 'Please enter a valid phone number';
    }
    return null;
  }
}

/// Email or phone validation rule
class EmailOrPhoneRule extends ValidationRule {
  const EmailOrPhoneRule({this.customMessage});

  final String? customMessage;

  @override
  String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return customMessage ?? 'Email or phone number is required';
    }

    const emailRule = EmailRule();
    const phoneRule = PhoneRule();

    final emailError = emailRule.validate(value);
    final phoneError = phoneRule.validate(value);

    if (emailError != null && phoneError != null) {
      return customMessage ??
          'Please enter a valid email address or phone number';
    }
    return null;
  }
}

/// Password validation rule
class PasswordRule extends ValidationRule {
  const PasswordRule({
    this.minLength = 6,
    this.requireUppercase = false,
    this.requireLowercase = false,
    this.requireNumbers = false,
    this.requireSpecialChars = false,
    this.customMessage,
  });

  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;
  final String? customMessage;

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return customMessage ?? 'Password is required';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (requireNumbers && !value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (requireSpecialChars &&
        !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }
}

/// Password confirmation validation rule
class PasswordConfirmationRule extends ValidationRule {
  const PasswordConfirmationRule(this.getPassword, {this.customMessage});

  final String Function() getPassword;
  final String? customMessage;

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return customMessage ?? 'Please confirm your password';
    }

    if (value != getPassword()) {
      return customMessage ?? 'Passwords do not match';
    }
    return null;
  }
}

/// Field validator for form validation
class FieldValidator {
  FieldValidator(this.rules);

  final List<ValidationRule> rules;
  final RxString error = ''.obs;

  /// Validate the field with the given value
  bool validate(String? value) {
    for (final rule in rules) {
      final errorMessage = rule.validate(value);
      if (errorMessage != null) {
        error.value = errorMessage;
        return false;
      }
    }
    error.value = '';
    return true;
  }

  /// Clear error state
  void clearError() {
    error.value = '';
  }
}

/// Validation result for form submissions
class ValidationResult {
  const ValidationResult({required this.isValid, required this.errors});

  factory ValidationResult.success() =>
      const ValidationResult(isValid: true, errors: {});
  factory ValidationResult.failure(Map<String, String> errors) =>
      ValidationResult(isValid: false, errors: errors);

  final bool isValid;
  final Map<String, String> errors;
}

/// Centralized validation service for all forms
class ValidationService extends GetxService {
  static ValidationService get I => Get.find<ValidationService>();

  final Map<String, FieldValidator> _validators = {};

  /// Register a field validator for a specific field
  void registerValidator(String fieldKey, List<ValidationRule> rules) {
    _validators[fieldKey] = FieldValidator(rules);
  }

  /// Get validator for a specific field
  FieldValidator? getValidator(String fieldKey) {
    return _validators[fieldKey];
  }

  /// Validate a specific field
  bool validateField(String fieldKey, String? value) {
    final validator = _validators[fieldKey];
    if (validator == null) {
      // Return false to surface missing registrations during development
      return false;
    }
    return validator.validate(value);
  }

  /// Get error message for a specific field
  String getFieldError(String fieldKey) {
    return _validators[fieldKey]?.error.value ?? '';
  }

  /// Clear error for a specific field
  void clearFieldError(String fieldKey) {
    _validators[fieldKey]?.clearError();
  }

  /// Clear all field errors
  void clearAllErrors() {
    for (final validator in _validators.values) {
      validator.clearError();
    }
  }

  /// Validate all registered fields and return result
  ValidationResult validateForm(Map<String, String?> formData) {
    final errors = <String, String>{};
    var isValid = true;

    for (final entry in formData.entries) {
      final fieldKey = entry.key;
      final value = entry.value;

      if (!validateField(fieldKey, value)) {
        errors[fieldKey] = getFieldError(fieldKey);
        isValid = false;
      }
    }

    return ValidationResult(isValid: isValid, errors: errors);
  }

  /// Common validation presets
  static List<ValidationRule> get emailRequired => [
    const RequiredRule(),
    const EmailRule(),
  ];

  static List<ValidationRule> get phoneRequired => [
    const RequiredRule(),
    const PhoneRule(),
  ];

  static List<ValidationRule> get emailOrPhoneRequired => [
    const EmailOrPhoneRule(),
  ];

  static List<ValidationRule> get passwordRequired => [
    const PasswordRule(),
  ];

  static List<ValidationRule> get passwordStrong => [
    const PasswordRule(
      minLength: 8,
      requireUppercase: true,
      requireLowercase: true,
      requireNumbers: true,
      requireSpecialChars: true,
    ),
  ];

  /// Create password confirmation validator
  List<ValidationRule> passwordConfirmation(String password) => [
    const RequiredRule(),
    PasswordConfirmationRule(() => password),
  ];

  /// Dispose all validators
  void dispose() {
    for (final validator in _validators.values) {
      validator.error.close();
    }
    _validators.clear();
  }
}
