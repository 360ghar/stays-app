import 'package:flutter/material.dart';

/// Reusable property image carousel widget
class PropertyImageCarousel extends StatelessWidget {
  final List<String> images;
  final String heroPrefix;
  final Function(int)? onPageChanged;
  final double height;
  final bool enableHero;

  const PropertyImageCarousel({
    super.key,
    required this.images,
    required this.heroPrefix,
    this.onPageChanged,
    this.height = 300,
    this.enableHero = true,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: PageView.builder(
        itemCount: images.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final imageUrl = images[index];

          if (enableHero) {
            return Hero(
              tag: '${heroPrefix}_image_$index',
              child: _buildImage(imageUrl),
            );
          } else {
            return _buildImage(imageUrl);
          }
        },
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
      ),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
