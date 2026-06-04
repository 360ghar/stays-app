import 'package:flutter/material.dart';

extension ThemeContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textStyles => theme.textTheme;
  bool get isDark => theme.brightness == Brightness.dark;

  Color elevatedSurface([double overlayOpacity = 0.08]) {
    final overlay = (isDark ? Colors.white : Colors.black).withValues(
      alpha: overlayOpacity,
    );
    return Color.alphaBlend(overlay, colors.surface);
  }
}
