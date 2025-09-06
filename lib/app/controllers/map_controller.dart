import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/models/property_image_model.dart';
import 'package:stays_app/app/data/services/properties_service.dart';
import 'package:stays_app/app/data/services/location_service.dart';

class MapController extends GetxController {
  PropertiesService? _propertiesService;
  LocationService? _locationService;
  
  final MapController mapController = MapController();
  
  final RxList<Property> mapProperties = <Property>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Map state
  final Rx<LatLng> mapCenter = LatLng(40.7128, -74.0060).obs; // Default NYC
  final RxDouble mapZoom = 12.0.obs;
  final Rx<Property?> selectedProperty = Rx<Property?>(null);
  
  // Filter state
  final RxString filterPurpose = 'short_stay'.obs;
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
      _propertiesService = Get.find<PropertiesService>();
    } catch (e) {
      print('PropertiesService not found');
    }
    
    try {
      _locationService = Get.find<LocationService>();
      if (_locationService?.latitude != null && _locationService?.longitude != null) {
        mapCenter.value = LatLng(
          _locationService!.latitude!,
          _locationService!.longitude!,
        );
      }
    } catch (e) {
      print('LocationService not found');
    }
  }
  
  void _initializeMap() {
    loadMapProperties();
  }
  
  Future<void> loadMapProperties() async {
    if (_propertiesService == null) {
      _loadMockMapData();
      return;
    }
    
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      // Get properties near the current map center
      final properties = await _propertiesService!.getNearbyProperties(
        latitude: mapCenter.value.latitude,
        longitude: mapCenter.value.longitude,
        radiusKm: _getRadiusFromZoom(mapZoom.value),
        propertyType: filterPurpose.value,
        limit: 100, // Limit map markers
      );
      
      // Filter properties with valid coordinates
      mapProperties.value = properties.where((p) => p.hasLocation).toList();
      
    } catch (e) {
      // Fallback to fetching by city
      try {
        final properties = await _propertiesService!.getShortStayProperties(
          city: _locationService?.currentCity ?? 'New York',
          limit: 100,
        );
        
        // Filter properties with valid coordinates
        mapProperties.value = properties.where((p) => p.hasLocation).toList();
        
        // If no properties have coordinates, generate random ones for demo
        if (mapProperties.isEmpty) {
          _generateRandomCoordinates(properties);
        }
        
      } catch (e2) {
        errorMessage.value = 'Failed to load properties for map';
        print('Error loading map properties: $e2');
        _loadMockMapData();
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  void _generateRandomCoordinates(List<Property> properties) {
    final random = List.generate(properties.length, (index) {
      final baseLatLng = mapCenter.value;
      final offsetLat = (index % 10 - 5) * 0.01; // Spread around center
      final offsetLng = ((index ~/ 10) - 5) * 0.01;
      
      return Property(
        id: properties[index].id,
        name: properties[index].name,
        images: properties[index].images,
        city: properties[index].city,
        country: properties[index].country,
        pricePerNight: properties[index].pricePerNight,
        propertyType: properties[index].propertyType,
        rating: properties[index].rating,
        reviewsCount: properties[index].reviewsCount,
        latitude: baseLatLng.latitude + offsetLat,
        longitude: baseLatLng.longitude + offsetLng,
      );
    });
    
    mapProperties.value = random;
  }
  
  void _loadMockMapData() {
    isLoading.value = true;
    
    final baseLatLng = mapCenter.value;
    final mockProperties = List.generate(20, (index) {
      final offsetLat = (index % 10 - 5) * 0.01;
      final offsetLng = ((index ~/ 10) - 5) * 0.01;
      
      return Property(
        id: index,
        name: 'Property ${index + 1}',
        images: [
          PropertyImage(
            id: index,
            propertyId: index,
            imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945',
            displayOrder: 1,
            isMainImage: true,
          ),
        ],
        city: _locationService?.currentCity ?? 'New York',
        country: 'USA',
        pricePerNight: 100 + (index * 20).toDouble(),
        propertyType: index % 3 == 0 ? 'Hotel' : index % 3 == 1 ? 'Apartment' : 'Villa',
        rating: 4.0 + (index % 10) / 10,
        reviewsCount: 50 + index * 10,
        latitude: baseLatLng.latitude + offsetLat,
        longitude: baseLatLng.longitude + offsetLng,
      );
    });
    
    mapProperties.value = mockProperties;
    isLoading.value = false;
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
    String? purpose,
    double? minPrice,
    double? maxPrice,
    String? propertyType,
  }) {
    filterPurpose.value = purpose ?? 'short_stay';
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
    if (_locationService?.latitude != null && _locationService?.longitude != null) {
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
  }
  
  List<Property> getPropertiesInBounds(LatLngBounds bounds) {
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