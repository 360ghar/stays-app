import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/listing/listing_controller.dart';
import '../../../ui/widgets/cards/property_grid_card.dart';
import '../../../utils/helpers/responsive_helper.dart';

class SearchResultsView extends GetView<ListingController> {
  const SearchResultsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Properties'),
        actions: [
          IconButton(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded),
            onPressed: () {
              Get.snackbar('Sort', 'Sorting options coming soon');
            },
          ),
          IconButton(
            tooltip: 'Map',
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              Get.snackbar('Map', 'Map view coming soon');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: Obx(() {
          if (controller.isLoading.value && controller.listings.isEmpty) {
            // Keep scrollable to allow pull even when loading
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(child: CircularProgressIndicator()),
                SizedBox(height: 200),
              ],
            );
          }
          if (controller.listings.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(child: Text('No results')),
                SizedBox(height: 200),
              ],
            );
          }
          final crossAxisCount = ResponsiveHelper.value<int>(
            context: context,
            mobile: 1,
            tablet: 2,
            desktop: 3,
          );
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3 / 4,
            ),
            itemCount: controller.listings.length,
            itemBuilder: (_, i) {
              final p = controller.listings[i];
              return PropertyGridCard(
                property: p,
                heroPrefix: 'search_$i',
                onTap: () => Get.toNamed('/listing/${p.id}'),
              );
            },
          );
        }),
      ),
    );
  }
}
