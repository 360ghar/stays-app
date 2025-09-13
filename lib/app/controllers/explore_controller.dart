import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class ExploreController extends GetxController {
  // Services are guaranteed to be available by the time this controller is created.
  final LocationService _locationService = Get.find<LocationService>();
  final PropertiesRepository _propertiesRepository =
      Get.find<PropertiesRepository>();
  final WishlistRepository _wishlistRepository = Get.find<WishlistRepository>();

  final RxList<Property> popularHomes = <Property>[].obs;
  final RxList<Property> nearbyHotels =
      <Property>[].obs; // This can be fetched by location
  final RxSet<int> favoritePropertyIds = <int>{}.obs;
  final RxBool isLoading = true.obs; // Start with loading true
  final RxString errorMessage = ''.obs;

  String get locationName => _locationService.locationName.isEmpty
      ? 'this area'
      : _locationService.locationName;
  List<Property> get recommendedHotels => nearbyHotels.toList();

  Future<void> Function() get refreshLocation =>
      () async =>
          await _locationService.getCurrentLocation(ensurePrecise: true);
  VoidCallback get navigateToSearch =>
      () => Get.toNamed('/search');

  Future<void> useMyLocation() async {
    try {
      isLoading.value = true;
      await _locationService.updateLocation(ensurePrecise: true);
      await loadProperties();
      Get.snackbar(
        'Location Updated',
        'Using your current location for nearby stays',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppLogger.error('Failed to update location', e);
      Get.snackbar(
        'Location',
        'Unable to get your location. Check permissions.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _fetchInitialData();
    // Reload properties when user selects a new location
    ever<String>(_locationService.locationNameRx, (_) {
      loadProperties();
    });
  }

  Future<void> _fetchInitialData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // Use Future.wait to run fetches in parallel for better performance
      await loadProperties();
    } catch (e) {
      errorMessage.value = 'Failed to load data. Please pull to refresh.';
      AppLogger.error('Error fetching initial data', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadProperties() async {
    // Load nearby homes strictly by lat/lng/radius
    final resp = await _propertiesRepository.explore(limit: 10);
    popularHomes.value = resp.properties;

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

    try {
      if (isCurrentlyFavorite) {
        await _wishlistRepository.remove(propertyId);
        favoritePropertyIds.remove(propertyId);
      } else {
        await _wishlistRepository.add(propertyId);
        favoritePropertyIds.add(propertyId);
      }
      _updatePropertyFavoriteStatusInLists(propertyId, !isCurrentlyFavorite);
      Get.snackbar(
        isCurrentlyFavorite ? 'Removed from Wishlist' : 'Added to Wishlist',
        '${property.name} updated.',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      AppLogger.error('Error toggling favorite', e);
      Get.snackbar('Error', 'Could not update wishlist. Please try again.');
    }
  }

  void _updatePropertyFavoriteStatusInLists(int propertyId, bool isFavorite) {
    // This correctly updates the UI by creating a new instance of the Property
    int index = popularHomes.indexWhere((p) => p.id == propertyId);
    if (index != -1) {
      popularHomes[index] = popularHomes[index].copyWith(
        isFavorite: isFavorite,
      );
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
