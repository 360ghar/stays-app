import 'package:flutter/material.dart';

import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/ui/widgets/common/cached_image.dart';
import 'package:stays_app/core/theme/tokens.dart';

/// The single stay card. Replaces property_card, hotel_card, listing_card,
/// featured_property_card, property_grid_card (7 variants → 1).
///
/// Photo-first 4:3, 360 badge, heart, price bottom-left. Fixed height via
/// [width]; image keeps [StayTokens.ratioCard].
class StayCard extends StatelessWidget {
  const StayCard({
    required this.property,
    required this.onTap,
    super.key,
    this.onFavoriteToggle,
    this.width = 248,
    this.isFavorite = false,
  });
  final Property property;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final double width;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final imageUrl = property.displayImage;
    final fav = isFavorite || property.isFavorite;
    return Semantics(
      label:
          '${property.name}, ${property.fullAddress}, '
          '${property.displayPrice} per night',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: StayTokens.paper,
            borderRadius: BorderRadius.circular(StayTokens.radiusCard),
            border: Border.all(color: StayTokens.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: StayTokens.ratioCard,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Canonical image fallback lives in [CachedImage].
                    CachedImage(imageUrl: imageUrl, memCacheWidth: 600),
                    if (property.hasVirtualTour)
                      const Positioned(
                        left: StayTokens.s8,
                        top: StayTokens.s8,
                        child: _TourBadge(),
                      ),
                    Positioned(
                      right: StayTokens.s8,
                      top: StayTokens.s8,
                      child: _HeartButton(active: fav, onTap: onFavoriteToggle),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(StayTokens.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      property.name,
                      style: StayTokens.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: StayTokens.s4),
                    Text(
                      property.fullAddress,
                      style: StayTokens.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: StayTokens.s8),
                    Row(
                      children: [
                        Text(property.displayPrice, style: StayTokens.price),
                        const Text(' / night', style: StayTokens.label),
                        const Spacer(),
                        if (property.rating != null) ...[
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: StayTokens.star,
                          ),
                          const SizedBox(width: 2),
                          Text(property.ratingText, style: StayTokens.label),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourBadge extends StatelessWidget {
  const _TourBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(StayTokens.radiusPill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.threesixty, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            '360 Tour',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
        ),
        child: Icon(
          active ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: active ? StayTokens.heart : StayTokens.ink,
        ),
      ),
    );
  }
}
