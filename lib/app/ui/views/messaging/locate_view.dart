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
                            hintText: 'Search location...',
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
                            child: const Text('Clear'),
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
          Positioned(
            bottom: 120,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: colors.surface,
              onPressed: controller.getCurrentLocation,
              child: Obx(
                () => controller.isLoadingLocation.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.my_location, color: colors.primary),
              ),
            ),
          ),

          // Hotels Loading Indicator
          Obx(
            () => controller.isLoadingHotels.value
                ? Positioned(
                    bottom: 80,
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
                              'Loading hotels...',
                              style: textStyles.bodyMedium?.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Hotels Count
          Positioned(
            bottom: 80,
            left: 16,
            child: Obx(
              () =>
                  controller.hotels.isNotEmpty &&
                      !controller.isLoadingHotels.value
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${controller.hotels.length} hotels',
                        style: textStyles.labelSmall?.copyWith(
                          color: colors.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
