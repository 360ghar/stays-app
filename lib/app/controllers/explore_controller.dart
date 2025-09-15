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
      // Clear any previously selected (manual) location so repository uses GPS
      _locationService.clearSelectedLocation();
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
    // Fetch within a broader radius so nearby cities are included
    const double radiusKm = 100.0;
    final resp = await _propertiesRepository.explore(
      limit: 30,
      radiusKm: radiusKm,
    );

    final props = resp.properties;

    // Determine selected city for grouping
    final selectedCity = _selectedCityNormalized();

    // Partition into in-city and nearby, then sort by distance
    final inCity = <Property>[];
    final nearby = <Property>[];
    for (final p in props) {
      if (_isInSelectedCity(p.city, selectedCity)) {
        inCity.add(p);
      } else {
        nearby.add(p);
      }
    }

    int cmp(Property a, Property b) {
      final da = a.distanceKm ?? double.maxFinite;
      final db = b.distanceKm ?? double.maxFinite;
      return da.compareTo(db);
    }
    inCity.sort(cmp);
    nearby.sort(cmp);

    // Bind to UI sections
    popularHomes.value = inCity; // "Popular stays near {city}"
    nearbyHotels.value = nearby; // "Popular hotels near {city}" (nearby cities)
  }

  String _selectedCityNormalized() {
    // Prefer geocoded currentCity, fallback to last component of locationName
    final city = (_locationService.currentCity.isNotEmpty
            ? _locationService.currentCity
            : _locationService.locationName.split(',').last)
        .trim();
    return _normalizeCity(city);
  }

  bool _isInSelectedCity(String propertyCity, String normalizedTarget) {
    final pc = _normalizeCity(propertyCity);
    if (pc == normalizedTarget) return true;

    // Handle common synonyms
    String canonical(String s) {
      const map = {
        'gurgaon': 'gurugram',
        'bangalore': 'bengaluru',
        'bombay': 'mumbai',
        'delhi ncr': 'delhi',
      };
      return map[s] ?? s;
    }
    return canonical(pc) == canonical(normalizedTarget);
  }

  String _normalizeCity(String s) => s.toLowerCase().trim();

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
    final lat = _locationService.latitude;
    final lng = _locationService.longitude;
    Get.toNamed(
      '/search-results',
      arguments: {
        'category': categoryType,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'radius_km': 100.0,
      },
    );
  }
}
