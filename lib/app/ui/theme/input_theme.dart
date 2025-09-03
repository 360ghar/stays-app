import 'package:flutter/material.dart';

// Global input decoration theme builder
class InputTheme {
  // Default text style for all input fields
  static const TextStyle defaultInputTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 16,
  );
  
  // Default hint text style
  static TextStyle defaultHintTextStyle = TextStyle(
    color: Colors.grey.shade500,
    fontSize: 16,
  );
  
  // Create a decorated TextField with default black text
  static TextField textField({
    TextEditingController? controller,
    String? hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
    InputDecoration? decoration,
    TextStyle? style,
    int? maxLines = 1,
    bool? enabled,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTap: onTap,
      maxLines: maxLines,
      enabled: enabled,
      focusNode: focusNode,
      style: style ?? defaultInputTextStyle,
      decoration: decoration ?? InputDecoration(
        hintText: hintText,
        hintStyle: defaultHintTextStyle,
      ),
    );
  }
  
  // Create a decorated TextFormField with default black text
  static TextFormField textFormField({
    TextEditingController? controller,
    String? hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
    FormFieldValidator<String>? validator,
    InputDecoration? decoration,
    TextStyle? style,
    int? maxLines = 1,
    bool? enabled,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTap: onTap,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      focusNode: focusNode,
      style: style ?? defaultInputTextStyle,
      decoration: decoration ?? InputDecoration(
        hintText: hintText,
        hintStyle: defaultHintTextStyle,
      ),
    );
  }
}