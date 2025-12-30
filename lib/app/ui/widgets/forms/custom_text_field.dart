import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_dimensions.dart';

enum TextFieldSize { small, medium, large }

enum TextFieldVariant { outlined, filled, underlined }

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final bool obscureText;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final TextFieldSize size;
  final TextFieldVariant variant;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final String? helperText;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? contentPadding;

  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onTap,
    this.validator,
    this.size = TextFieldSize.medium,
    this.variant = TextFieldVariant.outlined,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.enabled = true,
    this.helperText,
    this.backgroundColor,
    this.borderColor,
    this.contentPadding,
  });

  double get _textFieldHeight {
    switch (size) {
      case TextFieldSize.small:
        return 40;
      case TextFieldSize.medium:
        return 48;
      case TextFieldSize.large:
        return 56;
    }
  }

  EdgeInsetsGeometry get _defaultPadding {
    switch (size) {
      case TextFieldSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
      case TextFieldSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case TextFieldSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    }
  }

  InputDecoration _buildDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final errorColor = theme.colorScheme.error;
    final outlineColor = theme.colorScheme.outline;

    switch (variant) {
      case TextFieldVariant.outlined:
        return InputDecoration(
          hintText: hintText,
          labelText: labelText,
          errorText: errorText,
          helperText: helperText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: false,
          enabled: enabled,
          isDense: true,
          contentPadding: contentPadding ?? _defaultPadding,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            borderSide: BorderSide(
              color: borderColor ?? outlineColor,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            borderSide: BorderSide(
              color: borderColor ?? outlineColor,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            borderSide: BorderSide(color: errorColor, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            borderSide: BorderSide(color: errorColor, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            borderSide: BorderSide(
              color: outlineColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        );

      case TextFieldVariant.filled:
        final fillColor = backgroundColor ?? theme.colorScheme.surfaceVariant;
        return InputDecoration(
          hintText: hintText,
          labelText: labelText,
          errorText: errorText,
          helperText: helperText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: fillColor,
          enabled: enabled,
          isDense: true,
          contentPadding: contentPadding ?? _defaultPadding,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            borderSide: BorderSide(color: errorColor, width: 1),
          ),
        );

      case TextFieldVariant.underlined:
        return InputDecoration(
          hintText: hintText,
          labelText: labelText,
          errorText: errorText,
          helperText: helperText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: false,
          enabled: enabled,
          isDense: true,
          contentPadding:
              contentPadding ?? const EdgeInsets.symmetric(vertical: 12),
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: borderColor ?? outlineColor,
              width: 1,
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: borderColor ?? outlineColor,
              width: 1,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: errorColor, width: 1),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: maxLines != null && maxLines! > 1 ? null : _textFieldHeight,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        readOnly: readOnly,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onTap: onTap,
        validator: validator,
        enabled: enabled,
        inputFormatters: inputFormatters,
        style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
        decoration: _buildDecoration(context),
      ),
    );
  }
}

class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool enabled;

  const SearchTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final onSurfaceVariantColor = theme.colorScheme.onSurfaceVariant;

    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        style: TextStyle(fontSize: 16, color: onSurfaceColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 16, color: onSurfaceVariantColor),
          prefixIcon: Icon(Icons.search, color: onSurfaceVariantColor),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: onSurfaceVariantColor),
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                  },
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
