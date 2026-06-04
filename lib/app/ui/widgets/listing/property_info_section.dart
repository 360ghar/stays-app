import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/property_model.dart';
import '../../../utils/helpers/currency_helper.dart';

/// Property basic information section widget
class PropertyInfoSection extends StatelessWidget {
  final Property property;
  final VoidCallback? onBookNow;
  final VoidCallback? onContact;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const PropertyInfoSection({
    super.key,
    required this.property,
    this.onBookNow,
    this.onContact,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildLocationRow(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildFavoriteButton(),
            ],
          ),

          const SizedBox(height: 12),

          // Price and rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildPriceSection(textTheme), _buildRatingRow()],
          ),

          const SizedBox(height: 16),

          // Action buttons
          if (onBookNow != null || onContact != null)
            _buildActionButtons(colors),

          const SizedBox(height: 16),

          // Property type and capacity
          _buildPropertyDetails(textTheme),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            property.address ?? '${property.city}, ${property.country}',
            style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onFavorite,
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildPriceSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CurrencyHelper.format(property.pricePerNight),
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Get.theme.colorScheme.primary,
          ),
        ),
        Text(
          'per night',
          style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRatingRow() {
    if (property.rating == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text(
          property.rating!.toStringAsFixed(1),
          style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (property.reviewsCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '(${property.reviewsCount})',
            style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme colors) {
    return Row(
      children: [
        if (onContact != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onContact,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Contact Host'),
            ),
          ),
        if (onBookNow != null && onContact != null) const SizedBox(width: 12),
        if (onBookNow != null)
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onBookNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Book Now'),
            ),
          ),
      ],
    );
  }

  Widget _buildPropertyDetails(TextTheme textTheme) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (property.bedrooms != null && property.bedrooms! > 0)
          _buildDetailChip(
            Icons.bed_outlined,
            '${property.bedrooms} ${property.bedrooms == 1 ? 'Bedroom' : 'Bedrooms'}',
          ),
        if (property.bathrooms != null && property.bathrooms! > 0)
          _buildDetailChip(
            Icons.bathtub_outlined,
            '${property.bathrooms} ${property.bathrooms == 1 ? 'Bathroom' : 'Bathrooms'}',
          ),
        if (property.maxGuests != null && property.maxGuests! > 0)
          _buildDetailChip(
            Icons.people_outline,
            '${property.maxGuests} ${property.maxGuests == 1 ? 'Guest' : 'Guests'}',
          ),
        if (property.propertyType.isNotEmpty)
          _buildDetailChip(Icons.apartment_outlined, property.propertyType),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            text,
            style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
