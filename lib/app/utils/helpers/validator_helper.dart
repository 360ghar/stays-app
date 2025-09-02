class ValidatorHelper {
  static String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'This field is required';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value)) return 'Please enter a valid email';
    return null;
  }
}

