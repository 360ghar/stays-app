import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/ui/theme/theme_extensions.dart';
import 'package:stays_app/app/utils/helpers/currency_helper.dart';

import 'package:stays_app/features/messaging/controllers/hotels_map_controller.dart';

double? _shrinkFont(double? size, [double delta = 1]) =>
    size != null ? math.max(0, size - delta) : null;

class LocateView extends GetView<HotelsMapController> {
  const LocateView({super.key});

  void _openSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocateSearchSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterController = Get.find<FilterController>();
    final filtersRx = filterController.rxFor(FilterScope.locate);
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Scaffold(
      body: Stack(
        children: [
          Obx(
            () => flutter_map.FlutterMap(
              mapController: controller.mapController,
              options: flutter_map.MapOptions(
                initialCenter: controller.currentLocation.value,
                initialZoom: 12,
                minZoom: 5,
                maxZoom: 18,
                onMapReady: controller.onMapReady,
              ),
              children: [
                flutter_map.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.stays_app',
                  maxZoom: 18,
                ),
                // Rebuild only markers when the list changes
                Obx(
                  () => flutter_map.MarkerLayer(
                    markers: controller.markers.toList(),
                  ),
                ),
              ],
            ),
          ),

          // Top Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Obx(
                            () => _LocationChip(
                              label: controller.locationLabel.value,
                              isLoading: controller.isLoadingLocation.value,
                              onTap: () => _openSearchSheet(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Obx(() {
                        final active = filtersRx.value.isNotEmpty;
                        return _MapActionButton(
                          icon: Icons.tune_rounded,
                          isActive: active,
                          onTap: () => filterController.openFilterSheet(
                            context,
                            FilterScope.locate,
                          ),
                        );
                      }),
                    ],
                  ),
                  Obx(() {
                    final tags = filtersRx.value.activeTags();
                    if (tags.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ...tags.map((tag) => _FilterTagChip(label: tag)),
                          GestureDetector(
                            onTap: () =>
                                filterController.clear(FilterScope.locate),
                            child: Text(
                              'common.clear'.tr,
                              style: textStyles.labelMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Current Location Button
          Obx(() {
            final hasHotels = controller.hotels.isNotEmpty;
            final bottomOffset = hasHotels ? 230.0 : 140.0;
            return Positioned(
              right: 16,
              bottom: bottomOffset,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapControlButton(icon: Icons.add, onTap: controller.zoomIn),
                  const SizedBox(height: 12),
                  _MapControlButton(
                    icon: Icons.remove,
                    onTap: controller.zoomOut,
                  ),
                  const SizedBox(height: 12),
                  _MapControlButton(
                    icon: Icons.my_location_rounded,
                    isLoading: controller.isLoadingLocation.value,
                    onTap: controller.getCurrentLocation,
                  ),
                ],
              ),
            );
          }),

          // Hotels Loading Indicator
          Obx(() {
            if (!controller.isLoadingHotels.value) {
              return const SizedBox.shrink();
            }
            final hasHotels = controller.hotels.isNotEmpty;
            final bottomOffset = hasHotels ? 280.0 : 80.0;
            return Positioned(
              bottom: bottomOffset,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(
                      alpha: context.isDark ? 0.9 : 0.85,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'locate.loading_hotels'.tr,
                        style: textStyles.bodyMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Hotels Count
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Obx(() {
              final hotels = controller.hotels.toList();
              if (hotels.isEmpty) {
                return const SizedBox.shrink();
              }
              final selectedId = controller.selectedHotelId.value;
              return SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Builder(
                      builder: (context) {
                        final media = MediaQuery.of(context);
                        final screenHeight = media.size.height;
                        final cardHeight = math.max(
                          math.min(screenHeight * 0.24, 188.0),
                          165.0,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: SizedBox(
                            height: cardHeight,
                            child: PageView.builder(
                              controller: controller.cardsController,
                              padEnds: false,
                              clipBehavior: Clip.none,
                              physics: const BouncingScrollPhysics(),
                              onPageChanged: controller.onHotelCardChanged,
                              itemCount: hotels.length,
                              itemBuilder: (context, index) {
                                final hotel = hotels[index];
                                final isSelected = hotel.id == selectedId;
                                final opacity = isSelected ? 1.0 : 0.85;
                                return AnimatedPadding(
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOut,
                                  padding: EdgeInsets.only(
                                    left: index == 0 ? 8 : 6,
                                    right: index == hotels.length - 1 ? 24 : 6,
                                    top: isSelected ? 0 : 6,
                                    bottom: isSelected ? 6 : 12,
                                  ),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                    opacity: opacity,
                                    child: AnimatedScale(
                                      scale: isSelected ? 1.0 : 0.95,
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      curve: Curves.easeOutBack,
                                      alignment: Alignment.bottomCenter,
                                      child: LocatePropertyCard(
                                        hotel: hotel,
                                        isSelected: isSelected,
                                        onTap: () => controller
                                            .openPropertyDetail(hotel),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class LocatePropertyCard extends StatelessWidget {
  final HotelModel hotel;
  final VoidCallback onTap;
  final bool isSelected;

  const LocatePropertyCard({
    super.key,
    required this.hotel,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final isDark = context.isDark;
    final borderRadius = BorderRadius.circular(16);
    final shadowColor = Colors.black.withValues(
      alpha: isSelected ? (isDark ? 0.33 : 0.18) : (isDark ? 0.22 : 0.1),
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.outlineVariant.withValues(alpha: 0.26),
            width: isSelected ? 1.2 : 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: isSelected ? 18 : 12,
              offset: Offset(0, isSelected ? 6 : 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 10,
              child: _buildImage(context, isSelected: isSelected),
            ),
            Expanded(
              flex: 11,
              child: _buildDetails(
                context,
                textStyles,
                colors,
                contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, {required bool isSelected}) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageUrl = hotel.imageUrl;
    final property = hotel.property;
    final bedrooms = property.bedrooms;
    final hasBedrooms = bedrooms != null && bedrooms > 0;
    final distanceKm = hotel.distanceKm;
    Widget fallback = _buildPlaceholder(colors);
    Widget infoChip(String text, {IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: colors.primary, size: 12),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: _shrinkFont(
                  theme.textTheme.labelSmall?.fontSize,
                  1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Hero(
      tag: 'locate_${hotel.id}-${hotel.id}',
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
              ),
              errorWidget: (context, url, error) => fallback,
            )
          else
            fallback,
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: isSelected ? 0.28 : 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.92),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hotel.property.propertyTypeDisplay.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  fontSize: _shrinkFont(theme.textTheme.labelSmall?.fontSize, 1.5),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const _WishlistOverlayButton(),
                if (hotel.property.hasVirtualTour)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
              ],
            ),
          ),
          if (hasBedrooms || distanceKm > 0)
            Positioned(
              bottom: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasBedrooms)
                    infoChip('${bedrooms!} BHK', icon: Icons.king_bed_rounded),
                  if (hasBedrooms && distanceKm > 0) const SizedBox(height: 6),
                  if (distanceKm > 0)
                    infoChip('${distanceKm.toStringAsFixed(1)} km'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    TextTheme? textStyles,
    ColorScheme colors, {
    required EdgeInsets contentPadding,
  }) {
    final property = hotel.property;
    final priceText = CurrencyHelper.formatCompact(property.pricePerNight);
    final textTheme = textStyles ?? Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final address = property.fullAddress.isNotEmpty
        ? property.fullAddress
        : property.city;
    final baseTitleStyle = textTheme.titleSmall ?? textTheme.titleMedium;
    final titleStyle = baseTitleStyle?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: _shrinkFont(baseTitleStyle?.fontSize, 1),
      height: 1.05,
    );
    final priceStyle = textTheme.titleSmall?.copyWith(
      color: primary,
      fontWeight: FontWeight.w700,
      fontSize: _shrinkFont(textTheme.titleSmall?.fontSize, 1),
    );
    final addressStyle = textTheme.bodySmall?.copyWith(
      color: colors.onSurface.withValues(alpha: 0.6),
      height: 1.25,
    );
    final distanceStyle = textTheme.labelSmall?.copyWith(
      color: colors.onSurface.withValues(alpha: 0.58),
      fontSize: _shrinkFont(textTheme.labelSmall?.fontSize, 0.5),
    );

    Widget buildContent() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  property.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withOpacity(0.5)),
                ),
                child: Text(priceText, style: priceStyle),
              ),
            ],
          ),
          // Reduced spacing to prevent overflow
          const SizedBox(height: 1),
          Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: addressStyle,
          ),
          if (hotel.distanceKm > 0) ...[
            const SizedBox(height: 2),
            Text(
              '${hotel.distanceKm.toStringAsFixed(1)} km away',
              style: distanceStyle,
            ),
          ],
        ],
      );
    }

    return Padding(padding: contentPadding, child: buildContent());
  }

  Widget _buildPlaceholder(ColorScheme colors) {
    return Container(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: Icon(
        Icons.photo_outlined,
        color: colors.onSurface.withValues(alpha: 0.4),
        size: 42,
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.label,
    required this.onTap,
    required this.isLoading,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: 'Search location: $label',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          constraints: const BoxConstraints(maxWidth: 250),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.55),
              width: 1.1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded, color: colorScheme.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.expand_more_rounded,
                  color: colorScheme.onSurface.withOpacity(0.45),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = isActive
        ? colorScheme.primary
        : colorScheme.surfaceContainerLowest;
    final iconColor = isActive
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;
    return Material(
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.12),
      color: background,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.12),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
          ),
        ),
      ),
    );
  }
}

class _FilterTagChip extends StatelessWidget {
  const _FilterTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LocateSearchSheet extends StatelessWidget {
  const _LocateSearchSheet({required this.controller});

  final HotelsMapController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: TextField(
                    controller: controller.searchController,
                    autofocus: true,
                    onChanged: controller.onSearchChanged,
                    onSubmitted: controller.onSearchSubmitted,
                    decoration: InputDecoration(
                      hintText: 'Search locations or landmarks',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: Obx(
                        () => controller.isSearching.value
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: () {
                                  controller.searchController.clear();
                                  controller.onSearchChanged('');
                                },
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.6),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.4,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: Obx(() {
                    final items = controller.predictions.toList();
                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          top: 32,
                          left: 24,
                          right: 24,
                          bottom: 32,
                        ),
                        child: Text(
                          'Search for a city, neighbourhood, or landmark to explore stays nearby.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final prediction = items[index];
                          return ListTile(
                            leading: Icon(
                              Icons.place_outlined,
                              color: colorScheme.primary,
                            ),
                            title: Text(prediction.description),
                            onTap: () async {
                              await controller.selectPrediction(prediction);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WishlistOverlayButton extends StatefulWidget {
  const _WishlistOverlayButton();

  @override
  State<_WishlistOverlayButton> createState() => _WishlistOverlayButtonState();
}

class _WishlistOverlayButtonState extends State<_WishlistOverlayButton> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => setState(() => _saved = !_saved),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            _saved ? Icons.favorite : Icons.favorite_border,
            color: _saved ? Colors.redAccent : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
