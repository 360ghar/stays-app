import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/listing/listing_controller.dart';
import '../../../ui/widgets/cards/listing_card.dart';

class HomeView extends GetView<ListingController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Nearby')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.listings.isEmpty) {
          return const Center(child: Text('No listings yet'));
        }
        return ListView.separated(
          itemCount: controller.listings.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final item = controller.listings[i];
            return InkWell(
              onTap: () => Get.toNamed('/listing/${item.id}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListingCard(listing: item),
              ),
            );
          },
        );
      }),
    );
  }
}
