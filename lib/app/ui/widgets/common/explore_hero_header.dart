import 'package:flutter/material.dart';
import 'package:stays_app/app/ui/theme/theme_extensions.dart';

/// A hero greeting section for the Explore page.
/// Displays a time-based greeting without location badge.
class ExploreHeroHeader extends StatelessWidget {
  const ExploreHeroHeader({super.key});

  /// Returns a time-based greeting ("Good morning", "Good afternoon", "Good evening")
  static String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final greeting = getTimeBasedGreeting();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting text
          Text(
            greeting,
            style: textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
              height: 1.1,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          // Subtitle
          Text(
            'Discover stays around you',
            style: textStyles.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
