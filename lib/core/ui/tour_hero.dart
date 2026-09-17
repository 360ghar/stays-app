import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:stays_app/core/theme/tokens.dart';

/// Photo hero with a `View 360 Tour` pill. The flagship entry point.
///
/// Used at the top of the rebuilt listing detail. Tap opens `/tour/:id`.
class TourHero extends StatelessWidget {
  const TourHero({
    required this.imageUrl,
    required this.hasTour,
    required this.onTourTap,
    required this.onGalleryTap,
    super.key,
  });
  final String? imageUrl;
  final bool hasTour;
  final VoidCallback onTourTap;
  final VoidCallback onGalleryTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onGalleryTap,
      child: AspectRatio(
        aspectRatio: StayTokens.ratioHero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 1200,
                placeholder: (_, _) => Container(color: StayTokens.paperWarm),
                errorWidget: (_, _, _) =>
                    Container(color: StayTokens.paperWarm),
              )
            else
              Container(color: StayTokens.paperWarm),
            Positioned(
              bottom: StayTokens.s12,
              left: StayTokens.s12,
              right: StayTokens.s12,
              child: Row(
                children: [
                  if (hasTour)
                    GestureDetector(
                      onTap: onTourTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(
                            StayTokens.radiusPill,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.threesixty,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'View 360 Tour',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(
                        StayTokens.radiusPill,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Photos',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
