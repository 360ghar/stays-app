import 'package:flutter/material.dart';

import '../../theme/theme_extensions.dart';

class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    required this.onPressed,
    this.isActive = false,
  });

  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final activeColor = colorScheme.primary;
    final inactiveBorder = colorScheme.outlineVariant.withValues(alpha: 0.5);
    final baseSurface = isActive
        ? activeColor.withValues(alpha: context.isDark ? 0.25 : 0.15)
        : colorScheme.surface;
    return Material(
      color: baseSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? activeColor : inactiveBorder,
              width: 1.2,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  Icons.tune,
                  size: 24,
                  color: isActive
                      ? activeColor
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (isActive)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
