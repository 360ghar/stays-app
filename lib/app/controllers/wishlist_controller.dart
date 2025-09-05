import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WishlistController extends GetxController {
  final RxList<Map<String, dynamic>> wishlistItems = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadWishlist();
  }

  void loadWishlist() {
    isLoading.value = true;
    
    // Simulated wishlist items for demo
    Future.delayed(const Duration(seconds: 1), () {
      wishlistItems.value = [
        {
          'id': '1',
          'name': 'Luxury Villa with Ocean View',
          'image': 'https://images.unsplash.com/photo-1566073771259-6a8506099945',
          'location': 'Malibu, California',
          'price': 450,
          'rating': 4.8,
          'reviews': 234,
        },
        {
          'id': '2',
          'name': 'Downtown Modern Loft',
          'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2',
          'location': 'New York, NY',
          'price': 320,
          'rating': 4.6,
          'reviews': 189,
        },
        {
          'id': '3',
          'name': 'Cozy Mountain Cabin',
          'image': 'https://images.unsplash.com/photo-1587061949409-02df41d5e562',
          'location': 'Aspen, Colorado',
          'price': 280,
          'rating': 4.9,
          'reviews': 412,
        },
      ];
      isLoading.value = false;
    });
  }

  void addToWishlist(Map<String, dynamic> item) {
    if (!isInWishlist(item['id'])) {
      wishlistItems.add(item);
      Get.snackbar(
        'Added to Wishlist',
        '${item['name']} has been added to your wishlist',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void removeFromWishlist(String itemId) {
    wishlistItems.removeWhere((item) => item['id'] == itemId);
    Get.snackbar(
      'Removed from Wishlist',
      'Item has been removed from your wishlist',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  bool isInWishlist(String itemId) {
    return wishlistItems.any((item) => item['id'] == itemId);
  }

  void toggleWishlist(Map<String, dynamic> item) {
    if (isInWishlist(item['id'])) {
      removeFromWishlist(item['id']);
    } else {
      addToWishlist(item);
    }
  }

  void clearWishlist() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Wishlist'),
        content: const Text('Are you sure you want to remove all items from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              wishlistItems.clear();
              Get.back();
              Get.snackbar(
                'Wishlist Cleared',
                'All items have been removed from your wishlist',
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 2),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}