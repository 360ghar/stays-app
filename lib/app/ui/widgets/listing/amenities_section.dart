import 'package:flutter/material.dart';

/// Reusable amenities section widget
class AmenitiesSection extends StatelessWidget {
  final List<String> amenities;
  final String title;
  final bool expandable;
  final int initialItemCount;

  const AmenitiesSection({
    super.key,
    required this.amenities,
    this.title = 'Amenities',
    this.expandable = true,
    this.initialItemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();

    final displayItems = expandable && amenities.length > initialItemCount
        ? amenities.take(initialItemCount).toList()
        : amenities;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildAmenitiesGrid(displayItems, context),
          if (expandable && amenities.length > initialItemCount) ...[
            const SizedBox(height: 12),
            _buildShowAllButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAmenitiesGrid(List<String> amenitiesList, BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenitiesList
          .map((amenity) => _buildAmenityChip(amenity, context))
          .toList(),
    );
  }

  Widget _buildAmenityChip(String amenity, BuildContext context) {
    final icon = _getAmenityIcon(amenity);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              amenity,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowAllButton(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showAllAmenities(context),
        icon: const Icon(Icons.expand_more, size: 16),
        label: Text(
          'Show all ${amenities.length} amenities',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAllAmenities(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: amenities.length,
                  itemBuilder: (context, index) =>
                      _buildFullAmenityItem(amenities[index], context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullAmenityItem(String amenity, BuildContext context) {
    final icon = _getAmenityIcon(amenity);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(amenity, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final amenityLower = amenity.toLowerCase();

    if (amenityLower.contains('wifi') || amenityLower.contains('internet')) {
      return Icons.wifi_outlined;
    } else if (amenityLower.contains('pool')) {
      return Icons.pool_outlined;
    } else if (amenityLower.contains('parking')) {
      return Icons.local_parking_outlined;
    } else if (amenityLower.contains('kitchen')) {
      return Icons.kitchen_outlined;
    } else if (amenityLower.contains('air') || amenityLower.contains('ac')) {
      return Icons.ac_unit_outlined;
    } else if (amenityLower.contains('gym') ||
        amenityLower.contains('fitness')) {
      return Icons.fitness_center_outlined;
    } else if (amenityLower.contains('tv')) {
      return Icons.tv_outlined;
    } else if (amenityLower.contains('wash') ||
        amenityLower.contains('laundry')) {
      return Icons.local_laundry_service_outlined;
    } else if (amenityLower.contains('pet')) {
      return Icons.pets_outlined;
    } else if (amenityLower.contains('smoke')) {
      return Icons.smoke_free_outlined;
    } else {
      return Icons.check_circle_outline;
    }
  }
}
