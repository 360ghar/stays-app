import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Standardized [CachedNetworkImage] wrapper with a consistent shimmer
/// placeholder and broken-image fallback. Use everywhere an image is shown so
/// error/placeholder behavior is uniform (audit improvement #7).
class CachedImage extends StatelessWidget {
  const CachedImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.memCacheWidth,
    this.maxWidthDiskCache,
    super.key,
  });

  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double? borderRadius;
  final int? memCacheWidth;
  final int? maxWidthDiskCache;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final url = imageUrl;
    Widget child;
    if (url == null || url.isEmpty) {
      child = _placeholder(colors);
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: memCacheWidth,
        maxWidthDiskCache: maxWidthDiskCache,
        filterQuality: FilterQuality.medium,
        placeholder: (context, _) => _shimmer(colors),
        errorWidget: (context, _, __) => _error(colors),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: child,
      );
    }
    return child;
  }

  Widget _placeholder(ColorScheme colors) => Container(
    color: colors.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Icon(Icons.photo_outlined, color: colors.outline),
  );

  Widget _error(ColorScheme colors) => Container(
    color: colors.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Icon(Icons.broken_image_outlined, color: colors.outline),
  );

  Widget _shimmer(ColorScheme colors) => Shimmer.fromColors(
    baseColor: colors.surfaceContainerHighest,
    highlightColor: colors.surfaceContainerLow,
    child: Container(
      color: colors.surfaceContainerHighest,
      width: width,
      height: height,
    ),
  );
}
