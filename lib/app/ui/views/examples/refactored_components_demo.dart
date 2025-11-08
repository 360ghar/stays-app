import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/property_model.dart';
import '../../widgets/listing/property_image_carousel.dart';
import '../../widgets/listing/property_info_section.dart';
import '../../widgets/listing/amenities_section.dart';
import '../../../utils/services/widget_optimizer.dart';

/// Demo page showcasing the refactored components
class RefactoredComponentsDemo extends StatelessWidget {
  const RefactoredComponentsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final mockProperty = _createMockProperty();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refactored Components Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: WidgetOptimizer.optimizedListView(
        itemCount: 4,
        itemBuilder: (context, index) {
          return _buildSection(context, index, mockProperty);
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, int index, Property property) {
    switch (index) {
      case 0:
        return _buildImageSection(property);
      case 1:
        return _buildInfoSection(property);
      case 2:
        return _buildAmenitiesSection(property);
      case 3:
        return _buildPerformanceDemo(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildImageSection(Property property) {
    final images = property.images?.map((img) => img.imageUrl).toList();
    final imageList = (images == null || images.isEmpty)
        ? ['https://via.placeholder.com/400x300']
        : images;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optimized Image Carousel',
            style: Get.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PropertyImageCarousel(
              images: imageList,
              heroPrefix: 'demo_property',
              height: 250,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Property property) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: PropertyInfoSection(
        property: property,
        onBookNow: () {
          Get.snackbar(
            'Booking',
            'Book Now tapped for ${property.name}',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        onContact: () {
          Get.snackbar(
            'Contact',
            'Contact Host tapped for ${property.name}',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        onFavorite: () {
          Get.snackbar(
            'Favorites',
            'Favorite toggled for ${property.name}',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        isFavorite: false,
      ),
    );
  }

  Widget _buildAmenitiesSection(Property property) {
    return AmenitiesSection(
      amenities: property.amenities ?? [],
      title: 'Property Amenities',
      expandable: true,
    );
  }

  Widget _buildPerformanceDemo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Optimizations',
            style: Get.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPerformanceFeature(
            context,
            'Optimized ListView',
            'Uses RepaintBoundary and proper caching',
            Icons.list,
          ),
          _buildPerformanceFeature(
            context,
            'Memory Management',
            'Automatic cleanup in BaseController',
            Icons.memory,
          ),
          _buildPerformanceFeature(
            context,
            'Error Handling',
            'Centralized ErrorService integration',
            Icons.error_outline,
          ),
          _buildPerformanceFeature(
            context,
            'Token Security',
            'Secure token storage with refresh',
            Icons.security,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceFeature(BuildContext context, String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Property _createMockProperty() {
    return Property(
      id: 1,
      name: 'Luxury Beach Villa',
      propertyType: 'Villa',
      purpose: 'short_stay',
      city: 'Miami',
      country: 'USA',
      pricePerNight: 250.0,
      currency: 'USD',
      bedrooms: 4,
      bathrooms: 3,
      maxGuests: 8,
      rating: 4.8,
      reviewsCount: 127,
      description: 'Beautiful beachfront villa with stunning ocean views',
      amenities: [
        'WiFi',
        'Air Conditioning',
        'Swimming Pool',
        'Kitchen',
        'Parking',
        'Beach Access',
        'Smart TV',
        'Washer/Dryer',
      ],
      images: [],
      address: '123 Ocean Drive, Miami Beach',
      isFavorite: false,
    );
  }
}