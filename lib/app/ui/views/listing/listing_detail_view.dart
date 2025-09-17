import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/listing/listing_detail_controller.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../../data/models/property_model.dart';
import '../../../bindings/booking_binding.dart';
import '../booking/booking_view.dart';

class ListingDetailView extends GetView<ListingDetailController> {
  const ListingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'];
    final arg = Get.arguments;
    if (arg is Property && (controller.listing.value == null)) {
      controller.listing.value = arg;
    }
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
                child:
                    (listing.images != null && listing.images!.isNotEmpty)
                        ? PageView(
                          children:
                              listing.images!
                                  .map(
                                    (img) => Image.network(
                                      img.imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  .toList(),
                        )
                        : (listing.displayImage.isNotEmpty)
                        ? Image.network(listing.displayImage, fit: BoxFit.cover)
                        : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image, size: 48),
                          ),
                        ),
              ),
              if ((listing.virtualTourUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: const Row(
                    children: [
                      Text(
                        '360° Virtual Tour',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.threesixty),
                      label: const Text('Start Virtual Tour'),
                      onPressed: () async {
                        final raw = listing.virtualTourUrl!;
                        final uri = Uri.tryParse(raw);
                        if (uri == null) {
                          Get.snackbar(
                            'Invalid link',
                            'Virtual tour link is malformed',
                          );
                          return;
                        }
                        try {
                          final ok = await canLaunchUrl(uri);
                          if (!ok) {
                            Get.snackbar(
                              'Cannot open',
                              'Unable to open the virtual tour link',
                            );
                            return;
                          }
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {
                          Get.snackbar(
                            'Error',
                            'Failed to launch the virtual tour',
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${listing.city}, ${listing.country}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star_rate_rounded, size: 18),
                        Text(
                          '${(listing.rating ?? 0).toStringAsFixed(1)} (${listing.reviewsCount ?? 0})',
                        ),
                        const Spacer(),
                        Text(
                          CurrencyHelper.format(listing.pricePerNight),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Text(' · per night'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(listing.description ?? ''),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          (listing.amenities ?? [])
                              .map((a) => Chip(label: Text(a)))
                              .toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(
                            () => const BookingView(),
                            binding: BookingBinding(),
                            arguments: listing,
                          );
                        },
                        child: const Text('Book Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
