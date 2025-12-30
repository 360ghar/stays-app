import 'dart:async';

import 'package:get/get.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/models/unified_filter_model.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/utils/constants/app_constants.dart';

import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/controllers/favorites_controller.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/utils/services/connectivity_service.dart';
import 'package:stays_app/app/data/services/image_prefetch_service.dart';
import 'package:stays_app/app/utils/mixins/favorite_toggle_mixin.dart';

class ExploreController extends BaseController
    with ImagePrefetchMixin, FavoriteToggleMixin {
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

  // FavoriteToggleMixin requirements
  @override
  WishlistRepository? get wishlistRepository => _wishlistRepository;

  @override
  FavoritesController get favoritesController => _favoritesController;

  final RxList<Property> popularHomes = <Property>[].obs;
  final RxList<Property> nearbyHotels =
      <Property>[].obs; // This can be fetched by location

  String get locationName => _locationService.locationName.isEmpty
      ? 'this area'
      : _locationService.locationName;
  String get nearbyCity => _selectedCityNormalized();
  List<Property> get recommendedHotels => nearbyHotels.toList();
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
    // Set initial loading state
    isLoading.value = true;
    super.onInit();
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

  @override
  void onClose() {
    _filterWorker?.dispose();
    _locationWorker?.dispose();
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
      // Wait for location service to initialize before loading properties
      await _waitForLocationInitialization();
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
    // Check connectivity first
    final connectivityService = _getConnectivityService();
    final isOnline = connectivityService?.isOnline.value ?? true;

    if (!isOnline) {
      isOffline.value = true;
      // Try to load cached data when offline
      final cached = _propertiesRepository.getOfflineExploreResults(
        lat: _locationService.latitude,
        lng: _locationService.longitude,
      );
      if (cached != null && cached.properties.isNotEmpty) {
        isShowingCachedData.value = true;
        _updatePropertiesFromResponse(cached.properties);
        AppLogger.info(
          'Loaded ${cached.properties.length} cached properties (offline mode)',
        );
        return;
      }
      errorMessage.value = 'You are offline. Please check your connection.';
      AppLogger.warning('No cached data available for offline mode');
      return;
    }

    // Online - clear offline flags
    isOffline.value = false;
    isShowingCachedData.value = false;

    // Fetch within a broader radius so nearby cities are included
    final double radiusKm = _activeFilters.radiusKm ?? 100.0;
    final resp = await _propertiesRepository.explore(
      limit: 30,
      radiusKm: radiusKm,
      filters: _activeFilters.toQueryParameters(),
    );

    final props = resp.properties;
    _updatePropertiesFromResponse(props);
  }

  ConnectivityService? _getConnectivityService() {
    try {
      return Get.find<ConnectivityService>();
    } catch (_) {
      return null;
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
      await loadProperties();
    } catch (e) {
      errorMessage.value = 'Unable to apply filters. Please pull to refresh.';
      AppLogger.error('Error applying explore filters', e);
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

  Future<void> toggleFavoriteProperty(Property property) async {
    final propertyId = property.id;
    final wasCurrentlyFavorite = isPropertyFavorite(propertyId);

    final result = await toggleFavorite(
      property,
      onSuccess: () {
        _updatePropertyFavoriteStatusInLists(propertyId, !wasCurrentlyFavorite);
      },
    );

    if (!result.success) {
      AppLogger.error('Failed to toggle favorite: ${result.errorMessage}');
    }
  }

  void _updatePropertyFavoriteStatusInLists(int propertyId, bool isFavorite) {
    // This correctly updates the UI by creating a new instance of the Property
    final index = popularHomes.indexWhere((p) => p.id == propertyId);
    if (index != -1) {
      popularHomes[index] = popularHomes[index].copyWith(
        isFavorite: isFavorite,
      );
    }
    // Update nearby hotels too
    final hotelIndex = nearbyHotels.indexWhere((p) => p.id == propertyId);
    if (hotelIndex != -1) {
      nearbyHotels[hotelIndex] = nearbyHotels[hotelIndex].copyWith(
        isFavorite: isFavorite,
      );
    }
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
