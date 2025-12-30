import 'package:flutter/material.dart';

enum ButtonSize { small, medium, large }

enum ButtonVariant { primary, secondary, outline, ghost, danger }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? leading;
  final Widget? trailing;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? semanticLabel;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.leading,
    this.trailing,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
  });

  double get _buttonHeight {
    if (size == ButtonSize.small) return 36;
    if (size == ButtonSize.large) return 56;
    return 48;
  }

  double get _buttonFontSize {
    if (size == ButtonSize.small) return 13;
    if (size == ButtonSize.large) return 16;
    return 14;
  }

  EdgeInsets get _buttonPadding {
    if (size == ButtonSize.small) {
      return const EdgeInsets.symmetric(horizontal: 12);
    }
    if (size == ButtonSize.large) {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  ButtonStyle _getPrimaryStyle(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? colors.primary,
      foregroundColor: foregroundColor ?? colors.onPrimary,
      elevation: 0,
      shadowColor: (backgroundColor ?? colors.primary).withValues(alpha: 0.3),
      padding: _buttonPadding,
      minimumSize: Size(width ?? double.infinity, _buttonHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: TextStyle(
        fontSize: _buttonFontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  ButtonStyle _getSecondaryStyle(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? colors.secondary,
      foregroundColor: foregroundColor ?? colors.onSecondary,
      elevation: 0,
      padding: _buttonPadding,
      minimumSize: Size(width ?? double.infinity, _buttonHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: TextStyle(
        fontSize: _buttonFontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  ButtonStyle _getOutlineStyle(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: foregroundColor ?? colors.primary,
      padding: _buttonPadding,
      minimumSize: Size(width ?? double.infinity, _buttonHeight),
      side: BorderSide(color: colors.primary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: TextStyle(
        fontSize: _buttonFontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  ButtonStyle _getGhostStyle(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: foregroundColor ?? colors.primary,
      padding: _buttonPadding,
      minimumSize: Size(width ?? double.infinity, _buttonHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: TextStyle(
        fontSize: _buttonFontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  ButtonStyle _getDangerStyle(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? colors.error,
      foregroundColor: foregroundColor ?? colors.onError,
      elevation: 0,
      padding: _buttonPadding,
      minimumSize: Size(width ?? double.infinity, _buttonHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: TextStyle(
        fontSize: _buttonFontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  ButtonStyle _buildStyle(BuildContext context) {
    switch (variant) {
      case ButtonVariant.primary:
        return _getPrimaryStyle(context);
      case ButtonVariant.secondary:
        return _getSecondaryStyle(context);
      case ButtonVariant.outline:
        return _getOutlineStyle(context);
      case ButtonVariant.ghost:
        return _getGhostStyle(context);
      case ButtonVariant.danger:
        return _getDangerStyle(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final buttonStyle = _buildStyle(context);

    return Semantics(
      label: semanticLabel ?? text,
      button: true,
      enabled: !isLoading && onPressed != null,
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          style: buttonStyle,
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: _buttonFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
