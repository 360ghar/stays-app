import 'package:flutter/material.dart';

import '../../theme/theme_extensions.dart';

class SearchBarWidget extends StatelessWidget {
  final String placeholder;
  final VoidCallback onTap;
  final bool enabled;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Widget? leading;
  final Widget? trailing;
  final Color? backgroundColor;
  final double elevation;
  final EdgeInsetsGeometry margin;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final Color? shadowColor;

  const SearchBarWidget({
    super.key,
    this.placeholder = 'Start your search',
    required this.onTap,
    this.enabled = false,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.leading,
    this.trailing,
    this.backgroundColor,
    this.elevation = 2,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    this.height = 50,
    this.borderRadius,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final borderRadiusValue = borderRadius ?? BorderRadius.circular(30);
    final resolvedShadowColor =
        shadowColor ??
        colors.shadow.withValues(alpha: context.isDark ? 0.4 : 0.1);
    final resolvedBackground = backgroundColor ?? colors.surface;
    final borderColor = colors.outlineVariant.withValues(alpha: 0.4);
    final hintColor = colors.onSurface.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: enabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: margin,
        child: Material(
          elevation: elevation,
          borderRadius: borderRadiusValue,
          shadowColor: resolvedShadowColor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: resolvedBackground,
              borderRadius: borderRadiusValue,
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child:
                      leading ??
                      Icon(
                        Icons.search_rounded,
                        color: colors.onSurfaceVariant,
                        size: 24,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: enabled
                      ? TextField(
                          controller: controller,
                          onChanged: onChanged,
                          onSubmitted: onSubmitted,
                          autofocus: true,
                          style: textStyles.bodyMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: placeholder,
                            hintStyle: textStyles.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: hintColor,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        )
                      : Text(
                          placeholder,
                          style: textStyles.bodyMedium?.copyWith(
                            fontSize: 16,
                            color: hintColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: trailing,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
