import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/listing/listing_detail_controller.dart';
import '../../../utils/helpers/currency_helper.dart';

class ListingDetailView extends GetView<ListingDetailController> {
  const ListingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'];
    if (id != null) {
      // fire and forget
      controller.load(id);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Stay details')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final listing = controller.listing.value;
        if (listing == null) {
          return const Center(child: Text('Listing not found'));
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: PageView(
                  children: listing.images.isNotEmpty
                      ? listing.images
                          .map((url) => Image.network(url, fit: BoxFit.cover))
                          .toList()
                      : [Container(color: Colors.grey.shade300, child: const Icon(Icons.home, size: 48))],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${listing.location.city}, ${listing.location.country}',
                        style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star_rate_rounded, size: 18),
                        Text('${listing.rating.toStringAsFixed(1)} (${listing.reviewCount})'),
                        const Spacer(),
                        Text(CurrencyHelper.format(listing.pricePerNight),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Text(' · per night'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(listing.description),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: listing.amenities
                          .map((a) => Chip(label: Text(a.name)))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Book Now'),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      }),
    );
  }
}
