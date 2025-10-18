import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/listing/listing_detail_controller.dart';
import '../../../data/models/property_model.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../widgets/listing/interactive_virtual_tour.dart';

class ListingDetailView extends GetView<ListingDetailController> {
  const ListingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'];
    final arg = Get.arguments;
    if (arg is Property && controller.listing.value == null) {
      controller.setListing(arg);
    }
    if (id != null) {
      controller.load(id);
    }

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      extendBody: true,
      extendBodyBehindAppBar: false,
      body: Obx(() {
        if (controller.isLoading.value && controller.listing.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final listing = controller.listing.value;
        if (listing == null) {
          return const Center(child: Text('Listing not found'));
        }

        final amenities =
            (listing.amenities ?? [])
                .where((a) => a.trim().isNotEmpty)
                .toList();

        final features =
            (listing.features ?? []).where((f) => f.trim().isNotEmpty).toList();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),

          slivers: [
            _buildHeroSliver(context, listing),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),

              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPrimaryDetails(context, listing),

                  if (listing.hasVirtualTour)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),

                      child: _buildVirtualTourSection(context, listing),
                    ),

                  if (amenities.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),

                      child: _buildAmenitiesSection(context, amenities),
                    ),

                  if (features.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),

                      child: _buildFeaturesSection(context, features),
                    ),

                  if (listing.ownerName?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),

                      child: _buildHostSection(context, listing),
                    ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 120),
                ]),
              ),
            ),
          ],
        );
      }),

      bottomNavigationBar: Obx(() {
        final listing = controller.listing.value;
        if (listing == null) return const SizedBox.shrink();
        return _buildBookingBar(context, listing);
      }),
    );
  }

  SliverAppBar _buildHeroSliver(BuildContext context, Property listing) {
    final colors = Theme.of(context).colorScheme;

    final images = _resolveGalleryImages(listing);

    final itemCount = images.isNotEmpty ? images.length : 1;

    return SliverAppBar(
      backgroundColor: colors.surface,

      expandedHeight: 360,

      pinned: true,

      stretch: true,

      automaticallyImplyLeading: false,

      toolbarHeight: 64,

      titleSpacing: 0,

      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final settings =
              context
                  .dependOnInheritedWidgetOfExactType<
                    FlexibleSpaceBarSettings
                  >();

          final maxExtent = settings?.maxExtent ?? constraints.biggest.height;

          final minExtent = settings?.minExtent ?? kToolbarHeight;

          final currentExtent =
              settings?.currentExtent ?? constraints.biggest.height;

          final delta = maxExtent - minExtent;

          final progress =
              delta == 0
                  ? 0.0
                  : ((currentExtent - minExtent) / delta).clamp(0.0, 1.0);

          final collapsed = progress < 0.4;

          final iconColor = collapsed ? colors.onSurface : Colors.white;

          final overlayColor =
              Color.lerp(
                Colors.black.withValues(alpha: 0.35),
                colors.surface,
                collapsed ? 1 : 0,
              )!;

          return Stack(
            fit: StackFit.expand,

            children: [
              PageView.builder(
                controller: controller.galleryController,

                itemCount: itemCount,

                physics: const BouncingScrollPhysics(),

                onPageChanged: controller.updateImageIndex,

                itemBuilder: (context, index) {
                  final url = images.isNotEmpty ? images[index] : null;

                  if (url == null || url.isEmpty) {
                    return Container(
                      color: colors.surfaceContainerHighest,

                      alignment: Alignment.center,

                      child: Icon(
                        Icons.photo_outlined,

                        size: 48,

                        color: colors.onSurface.withValues(alpha: 0.45),
                      ),
                    );
                  }

                  return Image.network(
                    url,

                    fit: BoxFit.cover,

                    filterQuality: FilterQuality.medium,

                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;

                      return Container(
                        color: colors.surfaceContainerHighest,

                        alignment: Alignment.center,

                        child: const SizedBox(
                          height: 28,

                          width: 28,

                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      );
                    },

                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: colors.surfaceContainerHighest,

                        alignment: Alignment.center,

                        child: Icon(
                          Icons.broken_image_outlined,

                          size: 48,

                          color: colors.onSurface.withValues(alpha: 0.45),
                        ),
                      );
                    },
                  );
                },
              ),

              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,

                      end: Alignment.center,

                      colors: [
                        Colors.black.withValues(alpha: 0.55),

                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                bottom: false,

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),

                  decoration: BoxDecoration(color: overlayColor),

                  child: Row(
                    children: [
                      _HeroCircleButton(
                        icon: Icons.arrow_back,

                        color: iconColor,

                        background:
                            collapsed
                                ? colors.surfaceContainerHighest.withValues(
                                  alpha: 0.85,
                                )
                                : Colors.black.withValues(alpha: 0.45),

                        onTap: Get.back,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: AnimatedOpacity(
                          opacity: collapsed ? 1 : 0,

                          duration: const Duration(milliseconds: 200),

                          child: Text(
                            listing.name,

                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,

                              fontWeight: FontWeight.w600,
                            ),

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          _HeroCircleButton(
                            icon: Icons.ios_share_outlined,

                            color: iconColor,

                            background:
                                collapsed
                                    ? colors.surfaceContainerHighest.withValues(
                                      alpha: 0.85,
                                    )
                                    : Colors.black.withValues(alpha: 0.45),

                            onTap: () => _showComingSoon(context, 'Share stay'),
                          ),

                          const SizedBox(width: 12),

                          Obx(
                            () => _HeroCircleButton(
                              icon:
                                  controller.isPropertyFavorite(listing.id)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                              color:
                                  controller.isPropertyFavorite(listing.id)
                                      ? Colors.red
                                      : iconColor,
                              background:
                                  collapsed
                                      ? colors.surfaceContainerHighest
                                          .withValues(alpha: 0.85)
                                      : Colors.black.withValues(alpha: 0.45),
                              onTap: () => controller.toggleFavorite(listing),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                left: 20,

                right: 20,

                bottom: 28,

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    if (listing.propertyTypeDisplay.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,

                          vertical: 10,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),

                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Text(
                          listing.propertyTypeDisplay,

                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ),

                    Obx(() {
                      final index = controller.currentImageIndex.value;

                      final safeIndex = (index % itemCount) + 1;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,

                          vertical: 8,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),

                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Text(
                          '$safeIndex / $itemCount',

                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrimaryDetails(BuildContext context, Property listing) {
    final description = (listing.description ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleSection(context, listing),
        const SizedBox(height: 16),
        ..._buildHighlights(context, listing),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildAboutSection(context, description),
        ],
        const SizedBox(height: 24),
        _buildLocationSection(context, listing),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context, Property listing) {
    final textStyles = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.name,
          style: textStyles.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                listing.fullAddress.isNotEmpty
                    ? listing.fullAddress
                    : '${listing.city}, ${listing.country}',
                style: textStyles.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildHighlights(BuildContext context, Property listing) {
    final items = <MapEntry<IconData, String>>[];
    if ((listing.maxGuests ?? 0) > 0) {
      final guests = listing.maxGuests!;
      items.add(
        MapEntry(
          Icons.groups_2_outlined,
          '$guests ${guests == 1 ? 'guest' : 'guests'}',
        ),
      );
    }
    if ((listing.bedrooms ?? 0) > 0) {
      final count = listing.bedrooms!;
      items.add(
        MapEntry(
          Icons.king_bed_outlined,
          '$count ${count == 1 ? 'bedroom' : 'bedrooms'}',
        ),
      );
    }
    if ((listing.bathrooms ?? 0) > 0) {
      final count = listing.bathrooms!;
      items.add(
        MapEntry(
          Icons.bathtub_outlined,
          '$count ${count == 1 ? 'bath' : 'baths'}',
        ),
      );
    }
    if ((listing.parkingSpaces ?? 0) > 0) {
      final count = listing.parkingSpaces!;
      items.add(MapEntry(Icons.local_parking, '$count parking'));
    }
    if ((listing.squareFeet ?? 0) > 0) {
      final sqft = listing.squareFeet!.toStringAsFixed(0);
      items.add(MapEntry(Icons.square_foot_outlined, '$sqft sqft'));
    }

    if (items.isEmpty) return const [];

    return [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children:
            items
                .map((entry) => _InfoPill(icon: entry.key, label: entry.value))
                .toList(),
      ),
    ];
  }

  Widget _buildAboutSection(BuildContext context, String description) {
    final textStyles = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this stay',
          style: textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: textStyles.bodyMedium?.copyWith(
            height: 1.45,
            color: colors.onSurface.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildVirtualTourSection(BuildContext context, Property listing) {
    final textStyles = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Virtual tour',
          style: textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: InteractiveVirtualTour(
            tourUrl: listing.virtualTourUrl!,
            placeholderImageUrl: listing.displayImage,
            borderRadius: 16,
            aspectRatio: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open full tour'),
            onPressed: () {
              Get.toNamed(Routes.tour, arguments: listing.virtualTourUrl);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection(BuildContext context, List<String> amenities) {
    final textStyles = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final display = amenities.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What this place offers',
          style: textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children:
              display
                  .map(
                    (amenity) => _AmenityTile(
                      icon: _amenityIconFor(amenity),
                      label: amenity,
                    ),
                  )
                  .toList(),
        ),
        if (amenities.length > display.length)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton(
              onPressed:
                  () => _showListSheet(
                    context,
                    title: 'All amenities',
                    items: amenities,
                  ),
              child: const Text('Show all amenities'),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context, List<String> features) {
    final textStyles = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple header with icon
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: colors.onSurface.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Good to know',
                style: textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Simple list of features
          ...features.map(
            (feature) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: colors.primary.withValues(alpha: 0.8),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: textStyles.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context, Property listing) {
    final textStyles = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final distance = listing.distanceKm;
    final lat = listing.latitude;
    final lng = listing.longitude;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on_outlined, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Where you'll be staying",
                  style: textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Address text
          Text(
            listing.fullAddress.isNotEmpty
                ? listing.fullAddress
                : '${listing.city}, ${listing.country}',
            style: textStyles.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.85),
            ),
          ),

          if (distance != null) ...[
            const SizedBox(height: 10),
            Text(
              '${distance.toStringAsFixed(1)} km from your current search area',
              style: textStyles.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],

          // Map widget (only if coordinates are available)
          if (lat != null && lng != null) ...[
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: flutter_map.FlutterMap(
                  options: flutter_map.MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 15.0,
                    minZoom: 10.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    flutter_map.TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.stays_app',
                      maxZoom: 18,
                    ),
                    flutter_map.MarkerLayer(
                      markers: [
                        flutter_map.Marker(
                          point: LatLng(lat, lng),
                          width: 35,
                          height: 35,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: colors.onPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Directions button below the map
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openInMaps(listing),
                icon: const Icon(Icons.directions_outlined, size: 18),
                label: const Text('Get Directions'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHostSection(BuildContext context, Property listing) {
    final textStyles = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colors.primary.withValues(alpha: 0.1),
            child: Text(
              listing.ownerName!.substring(0, 1).toUpperCase(),
              style: textStyles.titleMedium?.copyWith(color: colors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hosted by ${listing.ownerName}',
                  style: textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                if (listing.ownerContact?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    listing.ownerContact!,
                    style: textStyles.bodyMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                if (listing.builderName?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Managed by ${listing.builderName}',
                    style: textStyles.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingBar(BuildContext context, Property listing) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final insets = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + insets),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyHelper.format(listing.pricePerNight),
                  style: textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '/ ${'listing.per_night'.tr}',
                  style: textStyles.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed:
                  () => controller.navigateToBookingConfirmation(listing),
              child: const Text('Book now'),
            ),
          ),
        ],
      ),
    );
  }

  void _showListSheet(
    BuildContext context, {
    required String title,
    required List<String> items,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final paddingBottom = MediaQuery.of(context).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, paddingBottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 60,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Text(
                title,
                style: textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: textStyles.bodyMedium?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openInMaps(Property listing) async {
    final lat = listing.latitude;
    final lng = listing.longitude;

    if (lat == null || lng == null) {
      Get.snackbar('Error', 'Location coordinates not available');
      return;
    }

    final url = 'geo:$lat,$lng?q=$lat,$lng';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        // Fallback to web maps
        final webUrl =
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
        if (await canLaunchUrl(Uri.parse(webUrl))) {
          await launchUrl(Uri.parse(webUrl));
        } else {
          Get.snackbar('Error', 'Could not open maps application');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not open maps application');
    }
  }

  void _showComingSoon(BuildContext context, String label) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$label coming soon',
          style: textStyles.bodyMedium?.copyWith(color: colors.onPrimary),
        ),
        backgroundColor: colors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<String> _resolveGalleryImages(Property listing) {
    final urls = <String>{};
    if (listing.displayImage?.isNotEmpty == true) {
      urls.add(listing.displayImage!);
    }
    for (final image in listing.images ?? const []) {
      if (image.imageUrl.isNotEmpty) {
        urls.add(image.imageUrl);
      }
    }
    return urls.toList();
  }

  IconData _amenityIconFor(String amenity) {
    final lower = amenity.toLowerCase();
    for (final entry in _amenityIconMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.check_circle_outline;
  }

  static const Map<String, IconData> _amenityIconMap = {
    'wifi': Icons.wifi,
    'internet': Icons.wifi,
    'parking': Icons.local_parking,
    'pool': Icons.pool,
    'gym': Icons.fitness_center,
    'fitness': Icons.fitness_center,
    'kitchen': Icons.restaurant,
    'breakfast': Icons.free_breakfast,
    'air': Icons.ac_unit,
    'ac': Icons.ac_unit,
    'conditioner': Icons.ac_unit,
    'tv': Icons.tv,
    'workspace': Icons.chair_alt,
    'desk': Icons.chair_alt,
    'laundry': Icons.local_laundry_service,
    'washer': Icons.local_laundry_service,
    'dryer': Icons.local_laundry_service,
    'pet': Icons.pets,
    'spa': Icons.spa,
    'security': Icons.shield_outlined,
    'elevator': Icons.elevator,
    'balcony': Icons.holiday_village,
    'garden': Icons.yard,
  };
}

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({
    required this.icon,

    required this.color,

    required this.background,

    required this.onTap,
  });

  final IconData icon;

  final Color color;

  final Color background;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 42,

        width: 42,

        decoration: BoxDecoration(
          color: background,

          borderRadius: BorderRadius.circular(16),
        ),

        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.onSurface.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Text(
            label,
            style: textStyles.labelMedium?.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _AmenityTile extends StatelessWidget {
  const _AmenityTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: colors.onSurface.withValues(alpha: 0.8),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: textStyles.bodyMedium?.copyWith(color: colors.onSurface),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
