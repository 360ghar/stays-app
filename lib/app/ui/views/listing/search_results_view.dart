import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/listing/listing_controller.dart';
import '../../../ui/widgets/cards/property_card.dart';
import '../../../utils/helpers/responsive_helper.dart';

class SearchResultsView extends GetView<ListingController> {
  const SearchResultsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Results')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.listings.isEmpty) {
          return const Center(child: Text('No results'));
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
            childAspectRatio: 16 / 14,
          ),
          itemCount: controller.listings.length,
          itemBuilder: (_, i) => PropertyCard(
            property: controller.listings[i],
            heroPrefix: 'search_$i',
            onTap: () => Get.toNamed('/listing/${controller.listings[i].id}'),
          ),
        );
      }),
    );
  }
}
