import 'package:flutter/material.dart';

import '../../theme/theme_extensions.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final TextStyle? subtitleStyle;
  final VoidCallback? onViewAll;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leadingIconColor,
    this.subtitleStyle,
    this.onViewAll,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedTitleStyle =
        titleStyle ??
        context.textStyles.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        );
    final resolvedSubtitleStyle =
        subtitleStyle ??
        context.textStyles.bodySmall?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.65),
        );

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: subtitle == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: subtitle == null
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    size: 18,
                    color: leadingIconColor ?? colors.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: resolvedTitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: resolvedSubtitleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
