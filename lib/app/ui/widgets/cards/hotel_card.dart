import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stays_app/app/data/models/hotel_model.dart';
import 'package:shimmer/shimmer.dart';

class HotelCard extends StatelessWidget {
  final Hotel hotel;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final double width;
  final double height;
  final bool showPrice;
  final bool showRating;
  final String? heroPrefix;

  const HotelCard({
    super.key,
    required this.hotel,
    required this.onTap,
    this.onFavoriteToggle,
    this.width = 280,
    this.height = 200,
    this.showPrice = true,
    this.showRating = true,
    this.heroPrefix,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 16),
        child: Hero(
          tag: '${heroPrefix ?? 'hotel'}-${hotel.id}',
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                _buildImage(),
                _buildGradientOverlay(),
                _buildContent(),
                if (onFavoriteToggle != null) _buildFavoriteButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: hotel.imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(width: width, height: height, color: Colors.white),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.error_outline, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hotel.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (showRating) ...[
                Icon(Icons.star_rounded, color: Colors.amber[400], size: 16),
                const SizedBox(width: 4),
                Text(
                  '${hotel.rating}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${hotel.reviews})',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
              const Spacer(),
              if (showPrice) ...[
                Text(
                  '${hotel.currency}${hotel.pricePerNight.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '/night',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: GestureDetector(
        onTap: onFavoriteToggle,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            hotel.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: hotel.isFavorite ? Colors.red : Colors.grey[700],
            size: 20,
          ),
        ),
      ),
    );
  }
}

class HotelCardShimmer extends StatelessWidget {
  final double width;
  final double height;

  const HotelCardShimmer({super.key, this.width = 280, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
