import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// A fullscreen, swipeable, zoomable image gallery.
///
/// Open with [showImageGallery]. Tapping the background or the close button
/// dismisses it. A page indicator reflects the current image (audit UX #15).
class ImageGalleryView extends StatefulWidget {
  const ImageGalleryView({
    required this.imageUrls,
    this.initialIndex = 0,
    super.key,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<ImageGalleryView> createState() => _ImageGalleryViewState();
}

class _ImageGalleryViewState extends State<ImageGalleryView> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) => setState(() => _index = index),
            builder: (context, index) {
              final url = widget.imageUrls[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(url),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: 'gallery_$index'),
                errorBuilder: (context, error, __) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.broken_image, color: Colors.white70, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Image could not load',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
          // Top bar with close + counter.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    if (widget.imageUrls.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_index + 1} / ${widget.imageUrls.length}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the fullscreen image gallery as a push route.
Future<void> showImageGallery(
  BuildContext context, {
  required List<String> imageUrls,
  int initialIndex = 0,
}) {
  if (imageUrls.isEmpty) return Future.value();
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          ImageGalleryView(imageUrls: imageUrls, initialIndex: initialIndex),
      fullscreenDialog: true,
    ),
  );
}
