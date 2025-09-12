import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/data/services/properties_service.dart';
import 'package:stays_app/app/data/services/wishlist_service.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class ExploreController extends GetxController {
  // Services are guaranteed to be available by the time this controller is created.
  final LocationService _locationService = Get.find<LocationService>();
  final PropertiesService _propertiesService = Get.find<PropertiesService>();
  final WishlistService _wishlistService = Get.find<WishlistService>();
  
  final RxList<Property> popularHomes = <Property>[].obs;
  final RxList<Property> nearbyHotels = <Property>[].obs; // This can be fetched by location
  final RxSet<int> favoritePropertyIds = <int>{}.obs;
  final RxBool isLoading = true.obs; // Start with loading true
  final RxString errorMessage = ''.obs;
  
  String get currentCity => _locationService.currentCity.isEmpty ? 'New York' : _locationService.currentCity;
  String get nearbyCity => currentCity;
  List<Property> get recommendedHotels => nearbyHotels.toList();
  
  Future<void> Function() get refreshLocation => () async => await _locationService.getCurrentLocation();
  VoidCallback get navigateToSearch => () => Get.toNamed('/search');

  @override
  void onInit() {
    super.onInit();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // Use Future.wait to run fetches in parallel for better performance
      await Future.wait([
        loadProperties(),
        // loadWishlist(), // Load wishlist data if you have a GET endpoint
      ]);
    } catch (e) {
      errorMessage.value = 'Failed to load data. Please pull to refresh.';
      AppLogger.error('Error fetching initial data', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadProperties() async {
    // Load popular homes for current city
    final popularProperties = await _propertiesService.getListings(
      location: currentCity,
      limit: 10,
    );
    popularHomes.value = popularProperties;
    
    // You can add another call for nearby properties if needed
  }

  Future<void> refreshData() async {
    await _fetchInitialData();
  }

  void navigateToPropertyDetail(Property property) {
    Get.toNamed('/listing/${property.id}', arguments: property);
  }

  Future<void> toggleFavorite(Property property) async {
    final propertyId = property.id;
    final isCurrentlyFavorite = favoritePropertyIds.contains(propertyId);
    
    bool success = false;
    try {
      if (isCurrentlyFavorite) {
        success = await _wishlistService.removeFromWishlist(propertyId: propertyId);
        if (success) favoritePropertyIds.remove(propertyId);
      } else {
        success = await _wishlistService.addToWishlist(propertyId: propertyId);
        if (success) favoritePropertyIds.add(propertyId);
      }
      
      if (success) {
        _updatePropertyFavoriteStatusInLists(propertyId, !isCurrentlyFavorite);
        Get.snackbar(
          isCurrentlyFavorite ? 'Removed from Wishlist' : 'Added to Wishlist',
          '${property.name} updated.',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        throw Exception('API call failed');
      }
    } catch (e) {
      AppLogger.error('Error toggling favorite', e);
      Get.snackbar('Error', 'Could not update wishlist. Please try again.');
    }
  }
  
  void _updatePropertyFavoriteStatusInLists(int propertyId, bool isFavorite) {
    // This correctly updates the UI by creating a new instance of the Property
    int index = popularHomes.indexWhere((p) => p.id == propertyId);
    if (index != -1) {
      popularHomes[index] = popularHomes[index].copyWith(isFavorite: isFavorite);
    }
    // Repeat for other lists like nearbyHotels if you have them
  }

  bool isPropertyFavorite(int propertyId) {
    return favoritePropertyIds.contains(propertyId);
  }
  
  void navigateToAllProperties(String categoryType) {
    Get.toNamed('/search-results', arguments: {'category': categoryType});
  }
}