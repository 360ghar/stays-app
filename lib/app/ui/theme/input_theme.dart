import 'package:flutter/material.dart';

// Global input decoration theme builder
class InputTheme {
  static TextStyle _defaultInputTextStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 16,
        ) ??
        TextStyle(color: colorScheme.onSurface, fontSize: 16);
  }

  static TextStyle _defaultHintTextStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 16,
        ) ??
        TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 16,
        );
  }

  // Create a decorated TextField with theme-aware defaults
  static TextField textField(
    BuildContext context, {
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
      style: style ?? _defaultInputTextStyle(context),
      decoration:
          decoration ??
          InputDecoration(
            hintText: hintText,
            hintStyle: _defaultHintTextStyle(context),
          ),
    );
  }

  // Create a decorated TextFormField with theme-aware defaults
  static TextFormField textFormField(
    BuildContext context, {
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
      style: style ?? _defaultInputTextStyle(context),
      decoration:
          decoration ??
          InputDecoration(
            hintText: hintText,
            hintStyle: _defaultHintTextStyle(context),
          ),
    );
  }
}
