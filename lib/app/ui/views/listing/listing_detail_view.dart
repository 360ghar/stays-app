import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/listing/listing_detail_controller.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../../data/models/property_model.dart';
import '../../widgets/web/virtual_tour_embed.dart';
import '../../../bindings/booking_binding.dart';
import '../booking/booking_view.dart';
import '../../../routes/app_routes.dart';

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
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stay details',
          style: textStyles.titleLarge?.copyWith(color: colors.onSurface),
        ),
      ),
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
                        : (listing.displayImage?.isNotEmpty == true)
                        ? Image.network(
                          listing.displayImage!,
                          fit: BoxFit.cover,
                        )
                        : Container(
                          color: colors.surfaceContainerHighest,
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
              ),
              if (listing.hasVirtualTour) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.threesixty, color: colors.primary),
                          const SizedBox(width: 8),
                          Text(
                            '360 Virtual Tour',
                            style: textStyles.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                          ),
                          child: VirtualTourEmbed(
                            url: listing.virtualTourUrl!,
                            height: 220,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open full tour'),
                          onPressed: () {
                            Get.toNamed(
                              Routes.tour,
                              arguments: listing.virtualTourUrl,
                            );
                          },
                        ),
                      ),
                    ],
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
                      style: textStyles.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${listing.city}, ${listing.country}',
                      style: textStyles.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star_rate_rounded, size: 18),
                        Text(
                          '${(listing.rating ?? 0).toStringAsFixed(1)} (${listing.reviewsCount ?? 0})',
                          style: textStyles.bodyMedium?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          CurrencyHelper.format(listing.pricePerNight),
                          style: textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          ' · ${'listing.per_night'.tr}',
                          style: textStyles.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      listing.description ?? '',
                      style: textStyles.bodyMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          (listing.amenities ?? [])
                              .map(
                                (a) => Chip(
                                  label: Text(
                                    a,
                                    style: textStyles.labelMedium?.copyWith(
                                      color: colors.onPrimaryContainer,
                                    ),
                                  ),
                                  backgroundColor: colors.primaryContainer,
                                ),
                              )
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
