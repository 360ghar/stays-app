import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/ui/widgets/common/filter_button.dart';
import '../../theme/theme_extensions.dart';

import '../../../controllers/messaging/hotels_map_controller.dart';

class LocateView extends GetView<HotelsMapController> {
  const LocateView({super.key});

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
            () => FlutterMap(
              mapController: controller.mapController,
              options: MapOptions(
                initialCenter: controller.currentLocation.value,
                initialZoom: 12,
                minZoom: 5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.stays_app',
                  maxZoom: 18,
                ),
                // Rebuild only markers when the list changes
                Obx(() => MarkerLayer(markers: controller.markers.toList())),
              ],
            ),
          ),

          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: context.isDark
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: colors.outlineVariant.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: controller.searchController,
                          onChanged: controller.onSearchChanged,
                          onSubmitted: controller.onSearchSubmitted,
                          decoration: InputDecoration(
                            hintText: 'locate.search_hint'.tr,
                            prefixIcon: Icon(
                              Icons.search,
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                            suffixIcon: Obx(
                              () =>
                                  (controller.isLoadingLocation.value ||
                                      controller.isSearching.value)
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: colors.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                      onPressed: () {
                                        controller.searchController.clear();
                                        controller.onSearchChanged('');
                                      },
                                    ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Obx(() {
                      final active = filtersRx.value.isNotEmpty;
                      return SizedBox(
                        height: 44,
                        child: FilterButton(
                          isActive: active,
                          onPressed: () => filterController.openFilterSheet(
                            context,
                            FilterScope.locate,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                Obx(() {
                  final tags = filtersRx.value.activeTags();
                  if (tags.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...tags.map(
                            (tag) => Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 10,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                filterController.clear(FilterScope.locate),
                            child: Text('common.clear'.tr),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                Obx(() {
                  if (controller.predictions.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: controller.predictions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = controller.predictions[index];
                          return ListTile(
                            leading: const Icon(Icons.place_outlined),
                            title: Text(p.description),
                            onTap: () => controller.selectPrediction(p),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Current Location Button
          Obx(() {
            final hasHotels = controller.hotels.isNotEmpty;
            final bottomOffset = hasHotels ? 280.0 : 120.0;
            final isLocating = controller.isLoadingLocation.value;
            return Positioned(
              bottom: bottomOffset,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: colors.surface,
                onPressed: controller.getCurrentLocation,
                child: isLocating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.my_location, color: colors.primary),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          bottom: 12,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'locate.hotels_count'.trParams({
                            'count': hotels.length.toString(),
                          }),
                          style: textStyles.labelSmall?.copyWith(
                            color: colors.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: (MediaQuery.of(context).size.height * 0.32)
                          .clamp(230.0, 300.0)
                          .toDouble(),
                      child: PageView.builder(
                        controller: controller.cardsController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: controller.onHotelCardChanged,
                        itemCount: hotels.length,
                        itemBuilder: (context, index) {
                          final hotel = hotels[index];
                          final isSelected = hotel.id == selectedId;
                          final cardWidth =
                              MediaQuery.of(context).size.width * 0.95;
                          return AnimatedPadding(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOut,
                            padding: EdgeInsets.only(
                              left: index == 0 ? 24 : 12,
                              right: index == hotels.length - 1 ? 24 : 12,
                              top: isSelected ? 0 : 12,
                              bottom: isSelected ? 8 : 16,
                            ),
                            child: AnimatedScale(
                              scale: isSelected ? 1 : 0.97,
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOut,
                              alignment: Alignment.bottomCenter,
                              child: LocatePropertyCard(
                                hotel: hotel,
                                width: cardWidth,
                                isSelected: isSelected,
                                onTap: () =>
                                    controller.openPropertyDetail(hotel),
                              ),
                            ),
                          );
                        },
                      ),
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
  final double width;

  const LocatePropertyCard({
    super.key,
    required this.hotel,
    required this.onTap,
    required this.isSelected,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 220, maxHeight: 300),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.18 : 0.1),
              blurRadius: isSelected ? 18 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              flex: 5,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 90),
                child: _buildImage(context),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 135),
              child: _buildDetails(context, textStyles, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final imageUrl = hotel.imageUrl;
    Widget fallback = _buildPlaceholder(colors);
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
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                hotel.property.propertyTypeDisplay,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (hotel.property.hasVirtualTour)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.threesixty, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '360°',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (hotel.distanceKm > 0)
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${hotel.distanceKm.toStringAsFixed(1)} km',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    TextTheme? textStyles,
    ColorScheme colors,
  ) {
    final property = hotel.property;
    final priceText = '${property.displayPrice}/${'listing.per_night'.tr}';
    final textTheme = textStyles ?? Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            property.name,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            property.fullAddress,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.65),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  priceText,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 38,
                child: FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_outward, size: 16),
                  label: Text('common.view_details'.tr),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
