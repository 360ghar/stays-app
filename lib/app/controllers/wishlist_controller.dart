import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/models/property_image_model.dart';
import 'package:stays_app/app/data/services/wishlist_service.dart';
import 'package:stays_app/app/data/services/properties_service.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class WishlistController extends GetxController {
  WishlistService? _wishlistService;
  PropertiesService? _propertiesService;
  
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
      _wishlistService = Get.find<WishlistService>();
    } catch (e) {
      AppLogger.warning('WishlistService not found');
    }
    
    try {
      _propertiesService = Get.find<PropertiesService>();
    } catch (e) {
      AppLogger.warning('PropertiesService not found');
    }
  }

  Future<void> loadWishlist() async {
    if (_wishlistService == null) {
      _loadMockWishlist();
      return;
    }
    
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      // Get wishlist items from API
      final wishlistData = await _wishlistService!.getUserWishlist();
      
      // Extract property IDs from wishlist
      final propertyIds = wishlistData.map((item) => item.propertyId).toList();
      
      // Check if wishlist items include property details
      final List<Property> propertiesWithDetails = wishlistData
          .where((item) => item.property != null)
          .map((item) {
            final propertyData = item.property;
            if (propertyData is Map<String, dynamic>) {
              return Property.fromJson(propertyData);
            }
            return null;
          })
          .whereType<Property>()
          .toList();
      
      if (propertiesWithDetails.isNotEmpty) {
        wishlistItems.value = propertiesWithDetails;
      } else if (propertyIds.isNotEmpty && _propertiesService != null) {
        // Fetch property details if not included
        final properties = <Property>[];
        for (final id in propertyIds) {
          try {
            final property = await _propertiesService!.getPropertyById(id.toString());
            properties.add(property);
          } catch (e) {
            AppLogger.error('Error fetching property $id', e);
          }
        }
        wishlistItems.value = properties;
      }
    } catch (e) {
      errorMessage.value = 'Failed to load wishlist';
      AppLogger.error('Error loading wishlist', e);
      _loadMockWishlist();
    } finally {
      isLoading.value = false;
    }
  }
  
  void _loadMockWishlist() {
    isLoading.value = true;
    
    // Simulated wishlist items for demo
    Future.delayed(const Duration(seconds: 1), () {
      wishlistItems.value = [
        Property(
          id: 1,
          name: 'Luxury Villa with Ocean View',
          images: [
            PropertyImage(
              id: 1,
              propertyId: 1,
              imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945',
              displayOrder: 1,
              isMainImage: true,
            ),
          ],
          city: 'Malibu',
          country: 'California',
          pricePerNight: 450,
          rating: 4.8,
          reviewsCount: 234,
          propertyType: 'Villa',
        ),
        Property(
          id: 2,
          name: 'Downtown Modern Loft',
          images: [
            PropertyImage(
              id: 2,
              propertyId: 2,
              imageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2',
              displayOrder: 1,
              isMainImage: true,
            ),
          ],
          city: 'New York',
          country: 'NY',
          pricePerNight: 320,
          rating: 4.6,
          reviewsCount: 189,
          propertyType: 'Loft',
        ),
        Property(
          id: 3,
          name: 'Cozy Mountain Cabin',
          images: [
            PropertyImage(
              id: 3,
              propertyId: 3,
              imageUrl: 'https://images.unsplash.com/photo-1587061949409-02df41d5e562',
              displayOrder: 1,
              isMainImage: true,
            ),
          ],
          city: 'Aspen',
          country: 'Colorado',
          pricePerNight: 280,
          rating: 4.9,
          reviewsCount: 412,
          propertyType: 'Cabin',
        ),
      ];
      isLoading.value = false;
    });
  }

  Future<void> addToWishlist(Property property) async {
    if (isInWishlist(property.id)) return;
    
    if (_wishlistService == null) {
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
      final success = await _wishlistService!.addToWishlist(
        propertyId: property.id,
      );
      
      if (success) {
        wishlistItems.add(property);
        Get.snackbar(
          'Added to Wishlist',
          '${property.name} has been added to your wishlist',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
      }
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
    
    if (_wishlistService == null) {
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
      final success = await _wishlistService!.removeFromWishlist(
        propertyId: propertyId,
      );
      
      if (success) {
        wishlistItems.removeWhere((p) => p.id == propertyId);
        Get.snackbar(
          'Removed from Wishlist',
          property != null 
              ? '${property.name} has been removed from your wishlist'
              : 'Item has been removed from your wishlist',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
      }
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
        content: const Text('Are you sure you want to remove all items from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              if (_wishlistService != null) {
                try {
                  final success = await _wishlistService!.clearWishlist();
                  if (success) {
                    wishlistItems.clear();
                    Get.snackbar(
                      'Wishlist Cleared',
                      'All items have been removed from your wishlist',
                      snackPosition: SnackPosition.TOP,
                      duration: const Duration(seconds: 2),
                    );
                  }
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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