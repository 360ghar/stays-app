import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class WishlistController extends GetxController {
  WishlistRepository? _wishlistRepository;

  final RxList<Property> wishlistItems = <Property>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    loadWishlist();
  }

  void _initializeServices() {
    try {
      _wishlistRepository = Get.find<WishlistRepository>();
    } catch (e) {
      AppLogger.warning('WishlistRepository not found');
    }
  }

  Future<void> loadWishlist() async {
    if (_wishlistRepository == null) {
      errorMessage.value = 'Wishlist service unavailable';
      wishlistItems.clear();
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final properties = await _wishlistRepository!.listFavorites();
      wishlistItems.value = properties;
    } catch (e) {
      errorMessage.value = 'Failed to load wishlist';
      AppLogger.error('Error loading wishlist', e);
      wishlistItems.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToWishlist(Property property) async {
    if (isInWishlist(property.id)) return;

    if (_wishlistRepository == null) {
      // Local add if service not available
      wishlistItems.add(property);
      Get.snackbar(
        'Added to Wishlist',
        '${property.name} has been added to your wishlist',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      await _wishlistRepository!.add(property.id);

      wishlistItems.add(property);
      Get.snackbar(
        'Added to Wishlist',
        '${property.name} has been added to your wishlist',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppLogger.error('Error adding to wishlist', e);
      Get.snackbar(
        'Error',
        'Failed to add to wishlist. Please try again.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> removeFromWishlist(int propertyId) async {
    final property = wishlistItems.firstWhereOrNull((p) => p.id == propertyId);

    if (_wishlistRepository == null) {
      // Local remove if service not available
      wishlistItems.removeWhere((p) => p.id == propertyId);
      Get.snackbar(
        'Removed from Wishlist',
        'Item has been removed from your wishlist',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      await _wishlistRepository!.remove(propertyId);

      wishlistItems.removeWhere((p) => p.id == propertyId);
      Get.snackbar(
        'Removed from Wishlist',
        property != null
            ? '${property.name} has been removed from your wishlist'
            : 'Item has been removed from your wishlist',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppLogger.error('Error removing from wishlist', e);
      Get.snackbar(
        'Error',
        'Failed to remove from wishlist. Please try again.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  bool isInWishlist(int propertyId) {
    return wishlistItems.any((p) => p.id == propertyId);
  }

  Future<void> toggleWishlist(Property property) async {
    if (isInWishlist(property.id)) {
      await removeFromWishlist(property.id);
    } else {
      await addToWishlist(property);
    }
  }

  void clearWishlist() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Wishlist'),
        content: const Text(
          'Are you sure you want to remove all items from your wishlist?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();

              if (_wishlistRepository != null) {
                try {
                  // No bulk clear; iterate
                  for (final p in wishlistItems.toList()) {
                    await _wishlistRepository!.remove(p.id);
                  }
                  wishlistItems.clear();
                  Get.snackbar(
                    'Wishlist Cleared',
                    'All items have been removed from your wishlist',
                    snackPosition: SnackPosition.TOP,
                    duration: const Duration(seconds: 2),
                  );
                } catch (e) {
                  AppLogger.error('Error clearing wishlist', e);
                  Get.snackbar(
                    'Error',
                    'Failed to clear wishlist. Please try again.',
                    snackPosition: SnackPosition.TOP,
                    duration: const Duration(seconds: 2),
                  );
                }
              } else {
                // Local clear if service not available
                wishlistItems.clear();
                Get.snackbar(
                  'Wishlist Cleared',
                  'All items have been removed from your wishlist',
                  snackPosition: SnackPosition.TOP,
                  duration: const Duration(seconds: 2),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> refresh() async {
    await loadWishlist();
  }
}
