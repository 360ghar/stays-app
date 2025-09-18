import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Extension helpers for retrieving theme-aware input styles
extension TextFieldThemeExtension on TextField {
  static TextStyle defaultInputStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 16,
        ) ??
        TextStyle(color: colorScheme.onSurface, fontSize: 16);
  }
}

/// Extension to provide theme-aware input styles for TextFormField widgets
extension TextFormFieldThemeExtension on TextFormField {
  static TextStyle defaultInputStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 16,
        ) ??
        TextStyle(color: colorScheme.onSurface, fontSize: 16);
  }
}

/// Custom TextField widget that ensures black text color
class ThemedTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool? enabled;
  final int? maxLines;
  final TextStyle? style;

  const ThemedTextField({
    super.key,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.decoration,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.enabled,
    this.maxLines = 1,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final inputStyle = TextFieldThemeExtension.defaultInputStyle(context);
    final hintStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ) ??
        TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        );
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onTap: onTap,
      focusNode: focusNode,
      enabled: enabled,
      maxLines: maxLines,
      style: inputStyle.merge(style),
      decoration:
          decoration ??
          InputDecoration(hintText: hintText, hintStyle: hintStyle),
    );
  }
}

/// Custom TextFormField widget that ensures black text color
class ThemedTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final bool? enabled;
  final int? maxLines;
  final TextStyle? style;

  const ThemedTextFormField({
    super.key,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.decoration,
    this.onChanged,
    this.onTap,
    this.validator,
    this.focusNode,
    this.enabled,
    this.maxLines = 1,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final inputStyle = TextFormFieldThemeExtension.defaultInputStyle(context);
    final hintStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ) ??
        TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        );
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onTap: onTap,
      validator: validator,
      focusNode: focusNode,
      enabled: enabled,
      maxLines: maxLines,
      style: inputStyle.merge(style),
      decoration:
          decoration ??
          InputDecoration(hintText: hintText, hintStyle: hintStyle),
    );
  }
}
