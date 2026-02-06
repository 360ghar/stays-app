import 'dart:async';

import 'package:get/get.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/models/unified_filter_model.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/utils/constants/app_constants.dart';

import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/controllers/favorites_controller.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/utils/helpers/haptic_helper.dart';
import 'package:stays_app/app/data/services/image_prefetch_service.dart';
import 'package:stays_app/app/data/services/analytics_service.dart';

class ExploreController extends BaseController with ImagePrefetchMixin {
  final LocationService _locationService;
  final PropertiesRepository _propertiesRepository;
  final WishlistRepository _wishlistRepository;
  final FilterController _filterController;
  final FavoritesController _favoritesController;

  final RxBool isOffline = false.obs;
  final RxBool isShowingCachedData = false.obs;

  UnifiedFilterModel _activeFilters = UnifiedFilterModel.empty;
  Worker? _filterWorker;
  Worker? _locationWorker;

  ExploreController({
    required LocationService locationService,
    required PropertiesRepository propertiesRepository,
    required WishlistRepository wishlistRepository,
    required FilterController filterController,
    required FavoritesController favoritesController,
  }) : _locationService = locationService,
       _propertiesRepository = propertiesRepository,
       _wishlistRepository = wishlistRepository,
       _filterController = filterController,
       _favoritesController = favoritesController;

  final RxList<Property> popularHomes = <Property>[].obs;
  final RxList<Property> nearbyHotels =
      <Property>[].obs; // This can be fetched by location

  String get locationName => _locationService.locationName.isEmpty
      ? 'this area'
      : _locationService.locationName;
  String get nearbyCity => _selectedCityNormalized();
  List<Property> get recommendedHotels => nearbyHotels.toList();

  /// Returns the property with the minimum distance from the current location.
  /// Considers both in-city and nearby properties. Returns null if no properties have distance data.
  Property? get nearestProperty {
    final allProperties = allExploreProperties;
    if (allProperties.isEmpty) return null;

    Property? nearest;
    double minDistance = double.infinity;

    for (final property in allProperties) {
      final distance = property.distanceKm;
      if (distance != null && distance < minDistance) {
        minDistance = distance;
        nearest = property;
      }
    }

    return nearest;
  }

  /// Returns a time-based greeting message.
  static String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Returns popular properties in the selected city, excluding the featured (nearest) property.
  List<Property> get popularInCity {
    final nearest = nearestProperty;
    return popularHomes.where((p) => p.id != nearest?.id).toList();
  }

  /// Returns nearby properties (from nearby cities), excluding the featured (nearest) property.
  List<Property> get nearbyStays {
    final nearest = nearestProperty;
    return nearbyHotels.where((p) => p.id != nearest?.id).toList();
  }

  List<Property> get allExploreProperties {
    final seen = <int>{};
    final combined = <Property>[];
    for (final property in popularHomes) {
      if (seen.add(property.id)) {
        combined.add(property);
      }
    }
    for (final property in nearbyHotels) {
      if (seen.add(property.id)) {
        combined.add(property);
      }
    }
    return combined;
  }

  Future<void> refreshLocation() async {
    await _locationService.getCurrentLocation(ensurePrecise: true);
    await _reloadWithFilters();
  }

  void navigateToSearch() {
    Get.toNamed('/search');
  }

  Future<void> useMyLocation() async {
    try {
      isLoading.value = true;
      // Clear any previously selected (manual) location so repository uses GPS
      _locationService.clearSelectedLocation();
      await _locationService.updateLocation(ensurePrecise: true);
      await loadProperties();
      AppSnackbar.success(
        title: 'Location Updated',
        message: 'Using your current location for nearby stays',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppLogger.error('Failed to update location', e);
      AppSnackbar.warning(
        title: 'Location',
        message: 'Unable to get your location. Check permissions.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    // Set initial loading state
    isLoading.value = true;
    super.onInit();
    _logScreenView();
    // _filterController is now injected via constructor
    _activeFilters = _filterController.filterFor(FilterScope.explore);
    _filterWorker = trackWorker(
      debounce<UnifiedFilterModel>(
        _filterController.rxFor(FilterScope.explore),
        (filters) async {
          if (_activeFilters == filters) return;
          _activeFilters = filters;
          await _reloadWithFilters();
        },
        time: const Duration(milliseconds: 180),
      ),
    );
    _fetchInitialData();
    // Reload properties when user selects a new location
    _locationWorker = trackWorker(
      ever<String>(_locationService.locationNameRx, (_) {
        _reloadWithFilters();
      }),
    );
  }

  void _logScreenView() {
    if (Get.isRegistered<AnalyticsService>()) {
      Get.find<AnalyticsService>().logScreenView('Explore');
    }
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> _waitForLocationInitialization() async {
    // Wait for location service to complete initialization
    const maxWaitTime = Duration(seconds: 10);
    final startTime = DateTime.now();

    while (!_locationService.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));

      // Prevent infinite waiting
      if (DateTime.now().difference(startTime) > maxWaitTime) {
        AppLogger.warning(
          'LocationService initialization timeout - proceeding anyway',
        );
        break;
      }
    }

    AppLogger.info(
      'LocationService initialization confirmed, proceeding with property loading',
    );
  }

  Future<void> _fetchInitialData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      AppLogger.info('ExploreController: Starting initial data fetch');
      // Wait for location service to initialize before loading properties
      await _waitForLocationInitialization();
      AppLogger.info(
        'ExploreController: Location initialized - '
        'lat: ${_locationService.latitude}, lng: ${_locationService.longitude}',
      );
      // Use Future.wait to run fetches in parallel for better performance
      await loadProperties();
      AppLogger.info(
        'ExploreController: Properties loaded - '
        'popular: ${popularHomes.length}, nearby: ${nearbyHotels.length}',
      );
    } catch (e, s) {
      AppLogger.error('ExploreController: Error fetching initial data', e, s);
      errorMessage.value = _getUserFriendlyErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Converts exceptions to user-friendly error messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Network connectivity issues
    if (errorStr.contains('connection') ||
        errorStr.contains('socket') ||
        errorStr.contains('network')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (errorStr.contains('timeout') || errorStr.contains('deadline')) {
      return 'Request timed out. Please try again.';
    }
    if (errorStr.contains('host') ||
        errorStr.contains('lookup') ||
        errorStr.contains('unreachable')) {
      return 'Cannot reach the server. Please check your connection.';
    }

    // Authentication issues
    if (errorStr.contains('401') || errorStr.contains('unauthorized') || errorStr.contains('token')) {
      return 'Session expired. Please log in again.';
    }
    if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return 'Access denied. Please log in again.';
    }

    // Server errors
    if (errorStr.contains('500') || errorStr.contains('502') || errorStr.contains('503') || errorStr.contains('504')) {
      return 'Server is temporarily unavailable. Please try again later.';
    }

    // Not found
    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return 'Requested resource not found.';
    }

    // Log the actual error for debugging
    AppLogger.warning('Unhandled error type: ${error.runtimeType} - $error');

    // Generic error message
    return 'Unable to load properties. Pull down to refresh.';
  }

  Future<void> loadProperties() async {
    // Clear offline flags before attempting to load
    isOffline.value = false;
    isShowingCachedData.value = false;

    try {
      // Fetch within a broader radius so nearby cities are included
      final double radiusKm = _activeFilters.radiusKm ?? 100.0;
      AppLogger.info(
        'ExploreController: Fetching properties - radius: $radiusKm, '
        'lat: ${_locationService.latitude}, lng: ${_locationService.longitude}',
      );

      final resp = await _propertiesRepository.explore(
        limit: 30,
        radiusKm: radiusKm,
        filters: _activeFilters.toQueryParameters(),
      );

      final props = resp.properties;
      AppLogger.info('ExploreController: Received ${props.length} properties from API');
      _updatePropertiesFromResponse(props);
    } catch (e, s) {
      AppLogger.error('ExploreController: Error loading properties', e, s);
      final friendlyError = _getUserFriendlyErrorMessage(e);

      // Try to load cached data on error (could be network issue)
      final cached = _propertiesRepository.getOfflineExploreResults(
        lat: _locationService.latitude,
        lng: _locationService.longitude,
      );
      if (cached != null && cached.properties.isNotEmpty) {
        isShowingCachedData.value = true;
        _updatePropertiesFromResponse(cached.properties);
        AppLogger.info(
          'Loaded ${cached.properties.length} cached properties due to error',
        );
        // Show cached data but also indicate there was an error
        errorMessage.value = '$friendlyError Showing cached data.';
        return;
      }

      // No cached data available, show the error
      isOffline.value = friendlyError.contains('internet') || friendlyError.contains('connection');
      errorMessage.value = friendlyError;
      rethrow;
    }
  }

  void _updatePropertiesFromResponse(List<Property> props) {
    final newFavorites = props
        .where((p) => p.isFavorite == true || p.liked == true)
        .map((p) => p.id);
    _favoritesController.addAll(newFavorites);

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

    // Prefetch images for visible properties
    _prefetchVisibleImages();
  }

  Future<void> _reloadWithFilters() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      AppLogger.info('ExploreController: Reloading with filters');
      await loadProperties();
    } catch (e, s) {
      AppLogger.error('ExploreController: Error applying explore filters', e, s);
      errorMessage.value = _getUserFriendlyErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Prefetch images for properties that will be displayed
  void _prefetchVisibleImages() {
    // Prefetch first batch of popular homes (usually displayed first)
    prefetchImages(popularHomes, limit: 6);
    
    // Prefetch first batch of nearby hotels
    prefetchImages(nearbyHotels, limit: 4);
    
    AppLogger.info(
      'Triggered image prefetch for ${popularHomes.length + nearbyHotels.length} properties',
    );
  }

  String _selectedCityNormalized() {
    // Prefer geocoded currentCity, fallback to last component of locationName
    final city =
        (_locationService.currentCity.isNotEmpty
                ? _locationService.currentCity
                : _locationService.locationName.split(',').last)
            .trim();
    return _normalizeCity(city);
  }

  bool _isInSelectedCity(String propertyCity, String normalizedTarget) {
    final pc = _normalizeCity(propertyCity);
    if (pc == normalizedTarget) return true;

    // Handle common synonyms
    String canonical(String s) => AppConstants.cityCanonicalMap[s] ?? s;

    return canonical(pc) == canonical(normalizedTarget);
  }

  String _normalizeCity(String s) => s.toLowerCase().trim();

  Future<void> refreshData() async {
    await _fetchInitialData();
  }

  void navigateToPropertyDetail(Property property) {
    Get.toNamed('/listing/${property.id}', arguments: property);
    
    // Prefetch all images for the property detail view
    prefetchDetailImages(property);
  }

  Future<void> toggleFavorite(Property property) async {
    final propertyId = property.id;
    final isCurrentlyFavorite = _favoritesController.isFavorite(propertyId);
    unawaited(HapticHelper.favoriteToggle());

    try {
      if (isCurrentlyFavorite) {
        await _wishlistRepository.remove(propertyId);
        _favoritesController.removeFavorite(propertyId);
        if (Get.isRegistered<AnalyticsService>()) {
          Get.find<AnalyticsService>().logWishlistRemoved('$propertyId');
        }
      } else {
        await _wishlistRepository.add(propertyId);
        _favoritesController.addFavorite(propertyId);
        if (Get.isRegistered<AnalyticsService>()) {
          Get.find<AnalyticsService>().logWishlistAdded('$propertyId');
        }
      }
      _updatePropertyFavoriteStatusInLists(propertyId, !isCurrentlyFavorite);
      AppSnackbar.success(
        title: isCurrentlyFavorite ? 'Removed from Wishlist' : 'Added to Wishlist',
        message: '${property.name} updated.',
      );
    } catch (e) {
      AppLogger.error('Error toggling favorite', e);
      AppSnackbar.error(
        title: 'Error',
        message: 'Could not update wishlist. Please try again.',
      );
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
    return _favoritesController.isFavorite(propertyId);
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
