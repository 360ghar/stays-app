import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:stays_app/app/data/models/property_model.dart';
// Removed mock image model dependency
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class MapController extends GetxController {
  PropertiesRepository? _propertiesRepository;
  LocationService? _locationService;

  final flutter_map.MapController mapController = flutter_map.MapController();

  final RxList<Property> mapProperties = <Property>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Map state
  final Rx<LatLng> mapCenter = LatLng(40.7128, -74.0060).obs; // Default NYC
  final RxDouble mapZoom = 12.0.obs;
  final Rx<Property?> selectedProperty = Rx<Property?>(null);

  // Filter state (non-location filters removed from backend query)
  final RxDouble? filterMinPrice = null;
  final RxDouble? filterMaxPrice = null;
  final RxString? filterPropertyType = null;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _initializeMap();
  }

  void _initializeServices() {
    try {
      _propertiesRepository = Get.find<PropertiesRepository>();
    } catch (e) {
      AppLogger.warning('PropertiesRepository not found');
    }

    try {
      _locationService = Get.find<LocationService>();
      if (_locationService?.latitude != null &&
          _locationService?.longitude != null) {
        mapCenter.value = LatLng(
          _locationService!.latitude!,
          _locationService!.longitude!,
        );
      }
    } catch (e) {
      AppLogger.warning('LocationService not found');
    }
  }

  void _initializeMap() {
    loadMapProperties();
  }

  Future<void> loadMapProperties() async {
    if (_propertiesRepository == null) {
      errorMessage.value = 'Properties service unavailable';
      mapProperties.clear();
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Get properties near the current map center
      final resp = await _propertiesRepository!.explore(
        lat: mapCenter.value.latitude,
        lng: mapCenter.value.longitude,
        radiusKm: _getRadiusFromZoom(mapZoom.value),
        limit: 100,
      );
      final properties = resp.properties;

      // Filter properties with valid coordinates
      mapProperties.value = properties.where((p) => p.hasLocation).toList();
    } catch (e) {
      errorMessage.value = 'Failed to load properties for map';
      AppLogger.error('Error loading map properties', e);
      mapProperties.clear();
    } finally {
      isLoading.value = false;
    }
  }

  double _getRadiusFromZoom(double zoom) {
    // Approximate radius based on zoom level
    if (zoom >= 15) return 2;
    if (zoom >= 13) return 5;
    if (zoom >= 11) return 10;
    if (zoom >= 9) return 25;
    if (zoom >= 7) return 50;
    return 100;
  }

  void onMapMoved(LatLng center, double zoom) {
    mapCenter.value = center;
    mapZoom.value = zoom;

    // Reload properties when map is moved significantly
    // Debounce this in production
    loadMapProperties();
  }

  void selectProperty(Property property) {
    selectedProperty.value = property;

    // Center map on selected property
    if (property.hasLocation) {
      mapCenter.value = LatLng(property.latitude!, property.longitude!);
      mapZoom.value = 15.0; // Zoom in on selection
    }
  }

  void clearSelection() {
    selectedProperty.value = null;
  }

  void navigateToPropertyDetail(Property property) {
    Get.toNamed('/listing/${property.id}', arguments: property);
  }

  void applyFilters({
    double? minPrice,
    double? maxPrice,
    String? propertyType,
  }) {
    // Store other filters and reload
    loadMapProperties();
  }

  void zoomIn() {
    if (mapZoom.value < 18) {
      mapZoom.value += 1;
    }
  }

  void zoomOut() {
    if (mapZoom.value > 3) {
      mapZoom.value -= 1;
    }
  }

  void centerOnUserLocation() {
    if (_locationService?.latitude != null &&
        _locationService?.longitude != null) {
      mapCenter.value = LatLng(
        _locationService!.latitude!,
        _locationService!.longitude!,
      );
      mapZoom.value = 14.0;
      loadMapProperties();
    } else {
      _locationService?.updateLocation(ensurePrecise: true).then((_) {
        if (_locationService?.latitude != null &&
            _locationService?.longitude != null) {
          mapCenter.value = LatLng(
            _locationService!.latitude!,
            _locationService!.longitude!,
          );
          mapZoom.value = 14.0;
          loadMapProperties();
        } else {
          Get.snackbar(
            'Location Not Available',
            'Please enable location services to center on your location',
            snackPosition: SnackPosition.TOP,
          );
        }
      });
    }
  }

  List<Property> getPropertiesInBounds(flutter_map.LatLngBounds bounds) {
    return mapProperties.where((property) {
      if (!property.hasLocation) return false;

      final lat = property.latitude!;
      final lng = property.longitude!;

      return lat >= bounds.south &&
          lat <= bounds.north &&
          lng >= bounds.west &&
          lng <= bounds.east;
    }).toList();
  }
}
