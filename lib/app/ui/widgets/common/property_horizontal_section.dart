import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/ui/theme/theme_extensions.dart';
import 'package:stays_app/app/ui/widgets/cards/property_grid_card.dart';
import 'package:stays_app/app/ui/widgets/common/section_header.dart';

/// A reusable horizontal scrolling section for property cards.
/// Displays a section title and a horizontally scrollable list of property cards.
class PropertyHorizontalSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final List<Property> properties;
  final bool isLoading;
  final VoidCallback? onViewAll;
  final void Function(Property)? onPropertyTap;
  final void Function(Property)? onFavoriteToggle;
  final bool Function(int)? isPropertyFavorite;
  final String sectionPrefix;
  final EdgeInsetsGeometry? padding;
  final String? emptyMessage;
  final double? cardHeight;
  final double? cardWidth;

  const PropertyHorizontalSection({
    super.key,
    required this.title,
    required this.properties,
    this.subtitle,
    this.leadingIcon,
    this.titleStyle,
    this.subtitleStyle,
    this.isLoading = false,
    this.onViewAll,
    this.onPropertyTap,
    this.onFavoriteToggle,
    this.isPropertyFavorite,
    this.sectionPrefix = 'section',
    this.padding,
    this.emptyMessage,
    this.cardHeight,
    this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (isLoading) {
      return _buildLoadingSection(context);
    }

    if (properties.isEmpty) {
      if (emptyMessage != null) {
        return _buildEmptySection(context, colors);
      }
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          leadingIcon: leadingIcon,
          titleStyle: titleStyle,
          subtitleStyle: subtitleStyle,
          onViewAll: properties.length > 3 ? onViewAll : null,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: cardHeight ?? 260,
          child: ListView.builder(
            key: ValueKey('${sectionPrefix}_list_${properties.length}'),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              final width = cardWidth ?? 240;
              return RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: SizedBox(
                    width: width,
                    child: PropertyGridCard(
                      property: property,
                      isCompact: true,
                      heroPrefix: '${sectionPrefix}_$index',
                      isFavorite: isPropertyFavorite?.call(property.id) ?? false,
                      onTap: () => onPropertyTap?.call(property),
                      onFavoriteToggle: onFavoriteToggle != null
                          ? () => onFavoriteToggle!(property)
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSection(BuildContext context) {
    final colors = context.colors;
    final width = cardWidth ?? 240;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          leadingIcon: leadingIcon,
          titleStyle: titleStyle,
          subtitleStyle: subtitleStyle,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: cardHeight ?? 260,
          child: ListView.builder(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _buildShimmerCard(context, colors, width),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard(
    BuildContext context,
    ColorScheme colors,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer image
            Expanded(
              flex: 3,
              child: Shimmer.fromColors(
                baseColor: colors.surfaceContainerHighest,
                highlightColor: colors.surface,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            // Shimmer content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: colors.surfaceContainerHighest,
                      highlightColor: colors.surface,
                      child: Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: colors.surfaceContainerHighest,
                      highlightColor: colors.surface,
                      child: Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySection(BuildContext context, ColorScheme colors) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.hotel_outlined,
                    size: 48,
                    color: colors.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    emptyMessage!,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
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
