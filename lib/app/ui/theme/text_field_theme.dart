import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Extension to provide consistent black text color for all TextField widgets
extension TextFieldThemeExtension on TextField {
  static const TextStyle defaultInputStyle = TextStyle(
    color: Colors.black,
    fontSize: 16,
  );
}

/// Extension to provide consistent black text color for all TextFormField widgets  
extension TextFormFieldThemeExtension on TextFormField {
  static const TextStyle defaultInputStyle = TextStyle(
    color: Colors.black,
    fontSize: 16,
  );
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
      // Always use black color for text, merge with provided style
      style: const TextStyle(color: Colors.black).merge(style),
      decoration: decoration ?? InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
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
      // Always use black color for text, merge with provided style
      style: const TextStyle(color: Colors.black).merge(style),
      decoration: decoration ?? InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
    );
  }
}