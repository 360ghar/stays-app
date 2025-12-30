 import 'package:cached_network_image/cached_network_image.dart';
 import 'package:flutter/material.dart';
 import 'package:flutter_cache_manager/flutter_cache_manager.dart';
 import 'package:get/get.dart';
 
 import '../../utils/logger/app_logger.dart';
 import '../models/property_model.dart';
 
 /// Service for prefetching images to improve perceived performance.
 /// Preloads property images before they're displayed to eliminate loading delays.
 class ImagePrefetchService extends GetxService {
   static ImagePrefetchService get I => Get.find<ImagePrefetchService>();
 
   final DefaultCacheManager _cacheManager = DefaultCacheManager();
   
   /// Track URLs currently being prefetched to avoid duplicates
   final Set<String> _prefetchingUrls = {};
   
   /// Track URLs that have been successfully prefetched
   final Set<String> _prefetchedUrls = {};
   
   /// Maximum concurrent prefetch operations
   static const int _maxConcurrentPrefetch = 5;
   
   /// Current number of active prefetch operations
   int _activePrefetches = 0;
   
   /// Queue of URLs waiting to be prefetched
   final List<String> _prefetchQueue = [];
 
   /// Initialize the service
   Future<ImagePrefetchService> init() async {
     AppLogger.info('ImagePrefetchService initialized');
     return this;
   }
 
   /// Prefetch a single image URL
   Future<void> prefetchImage(String? imageUrl) async {
     if (imageUrl == null || imageUrl.isEmpty) return;
     if (_prefetchedUrls.contains(imageUrl)) return;
     if (_prefetchingUrls.contains(imageUrl)) return;
     
     // Add to queue if at capacity
     if (_activePrefetches >= _maxConcurrentPrefetch) {
       if (!_prefetchQueue.contains(imageUrl)) {
         _prefetchQueue.add(imageUrl);
       }
       return;
     }
     
     await _executePrefetch(imageUrl);
   }
   
   Future<void> _executePrefetch(String imageUrl) async {
     _prefetchingUrls.add(imageUrl);
     _activePrefetches++;
     
     try {
       await _cacheManager.downloadFile(imageUrl);
       _prefetchedUrls.add(imageUrl);
       AppLogger.debug('Prefetched image: ${_truncateUrl(imageUrl)}');
     } catch (e) {
       // Silently fail - prefetching is best-effort
       AppLogger.debug('Failed to prefetch image: ${_truncateUrl(imageUrl)}');
     } finally {
       _prefetchingUrls.remove(imageUrl);
       _activePrefetches--;
       _processQueue();
     }
   }
   
   void _processQueue() {
     while (_prefetchQueue.isNotEmpty && _activePrefetches < _maxConcurrentPrefetch) {
       final nextUrl = _prefetchQueue.removeAt(0);
       if (!_prefetchedUrls.contains(nextUrl) && !_prefetchingUrls.contains(nextUrl)) {
         _executePrefetch(nextUrl);
       }
     }
   }
 
   /// Prefetch images for a list of properties
   Future<void> prefetchPropertyImages(List<Property> properties, {int limit = 10}) async {
     final urls = <String>[];
     
     for (int i = 0; i < properties.length && i < limit; i++) {
       final property = properties[i];
       final displayImage = property.displayImage;
       if (displayImage != null && displayImage.isNotEmpty) {
         urls.add(displayImage);
       }
     }
     
     for (final url in urls) {
       prefetchImage(url);
     }
     
     AppLogger.info('Queued ${urls.length} property images for prefetch');
   }
 
   /// Prefetch all images for a single property (for detail view)
   Future<void> prefetchPropertyDetailImages(Property property) async {
     final urls = <String>[];
     
     // Add display image
     final displayImage = property.displayImage;
     if (displayImage != null && displayImage.isNotEmpty) {
       urls.add(displayImage);
     }
     
     // Add all gallery images
    final images = property.images;
    if (images != null) {
      for (final image in images) {
        if (image.imageUrl.isNotEmpty) {
          urls.add(image.imageUrl);
        }
       }
     }
     
     for (final url in urls) {
       prefetchImage(url);
     }
     
     AppLogger.info('Queued ${urls.length} detail images for prefetch');
   }
 
   /// Prefetch images that will appear on next scroll
   /// Call this when user is near the end of visible items
   Future<void> prefetchNextBatch(
     List<Property> allProperties,
     int currentVisibleIndex,
     {int batchSize = 5}
   ) async {
     final startIndex = currentVisibleIndex + 1;
     final endIndex = (startIndex + batchSize).clamp(0, allProperties.length);
     
     if (startIndex >= allProperties.length) return;
     
     final nextProperties = allProperties.sublist(startIndex, endIndex);
     await prefetchPropertyImages(nextProperties, limit: batchSize);
   }
 
   /// Precache an image into Flutter's image cache (for immediate display)
   Future<void> precacheForDisplay(BuildContext context, String? imageUrl) async {
     if (imageUrl == null || imageUrl.isEmpty) return;
     
     try {
       await precacheImage(
         CachedNetworkImageProvider(imageUrl),
         context,
       );
     } catch (e) {
       // Silently fail
     }
   }
 
   /// Check if an image is already cached
   bool isImageCached(String? imageUrl) {
     if (imageUrl == null || imageUrl.isEmpty) return false;
     return _prefetchedUrls.contains(imageUrl);
   }
 
   /// Clear all prefetch tracking (cache remains)
   void clearPrefetchTracking() {
     _prefetchedUrls.clear();
     _prefetchQueue.clear();
   }
 
   /// Get prefetch statistics
   Map<String, int> get stats => {
     'prefetched': _prefetchedUrls.length,
     'queued': _prefetchQueue.length,
     'active': _activePrefetches,
   };
   
   String _truncateUrl(String url) {
     if (url.length <= 50) return url;
     return '${url.substring(0, 30)}...${url.substring(url.length - 17)}';
   }
 }
 
 /// Mixin for controllers that want to prefetch images
 mixin ImagePrefetchMixin {
   ImagePrefetchService? _imagePrefetchService;
   
   ImagePrefetchService get imagePrefetchService {
     _imagePrefetchService ??= Get.find<ImagePrefetchService>();
     return _imagePrefetchService!;
   }
   
   /// Prefetch images for properties
   void prefetchImages(List<Property> properties, {int limit = 10}) {
     if (Get.isRegistered<ImagePrefetchService>()) {
       imagePrefetchService.prefetchPropertyImages(properties, limit: limit);
     }
   }
   
   /// Prefetch detail images for a property the user might tap
   void prefetchDetailImages(Property property) {
     if (Get.isRegistered<ImagePrefetchService>()) {
       imagePrefetchService.prefetchPropertyDetailImages(property);
     }
   }
 }
