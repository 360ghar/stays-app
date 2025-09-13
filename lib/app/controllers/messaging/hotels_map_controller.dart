import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/repositories/properties_repository.dart';
import '../../data/models/property_model.dart';
import '../../data/services/places_service.dart';
import '../../data/services/location_service.dart';

class HotelModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double rating;
  final LatLng position;
  final String description;

  HotelModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.position,
    required this.description,
  });
}

class HotelsMapController extends GetxController {
  late MapController mapController;
  final RxList<Marker> markers = <Marker>[].obs;
  final RxList<HotelModel> hotels = <HotelModel>[].obs;
  final Rx<LatLng> currentLocation = const LatLng(
    28.6139,
    77.2090,
  ).obs; // Delhi default
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxList<PlacePrediction> predictions = <PlacePrediction>[].obs;
  final RxBool isLoadingLocation = false.obs;
  final RxBool isLoadingHotels = false.obs;
  final searchController = TextEditingController();
  PropertiesRepository? _propertiesService;
  PlacesService? _placesService;
  LocationService? _locationService;

  @override
  void onInit() {
    super.onInit();
    mapController = MapController();
    try {
      _propertiesService = Get.find<PropertiesRepository>();
    } catch (_) {}
    try {
      _placesService = Get.find<PlacesService>();
    } catch (_) {}
    try {
      _locationService = Get.find<LocationService>();
    } catch (_) {}
    debounce<String>(
      searchQuery,
      (q) => _searchAutocomplete(q),
      time: const Duration(milliseconds: 250),
    );
    _requestLocationPermission();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      await getCurrentLocation();
    } else {
      _loadSampleHotels();
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Location Error', 'Location services are disabled');
        _loadSampleHotels();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission Denied',
            'Location permission is required to show nearby hotels',
          );
          _loadSampleHotels();
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      currentLocation.value = LatLng(position.latitude, position.longitude);

      mapController.move(currentLocation.value, 12);

      await _loadHotelsNearLocation(currentLocation.value);
    } catch (e) {
      Get.snackbar('Error', 'Failed to get current location: $e');
      _loadSampleHotels();
    } finally {
      isLoadingLocation.value = false;
    }
  }

  Future<void> _loadHotelsNearLocation(LatLng location) async {
    isLoadingHotels.value = true;
    try {
      if (_propertiesService == null) {
        hotels.clear();
        return;
      }
      final resp = await _propertiesService!.explore(
        lat: location.latitude,
        lng: location.longitude,
        radiusKm: 10,
        limit: 50,
      );
      final mapped = resp.properties.map((p) => _toHotelModel(p)).toList();
      hotels.assignAll(mapped);
      _updateMapMarkers();
    } finally {
      isLoadingHotels.value = false;
    }
  }

  void _loadSampleHotels() {
    // Fallback: try to load from current location if service available
    _loadHotelsNearLocation(currentLocation.value);
  }

  void _updateMapMarkers() {
    final List<Marker> newMarkers = hotels.map((hotel) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: hotel.position,
        child: GestureDetector(
          onTap: () => _showHotelDetails(hotel),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '₹${hotel.price.toInt()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Icon(Icons.location_pin, color: Colors.red, size: 24),
            ],
          ),
        ),
      );
    }).toList();

    // Replace markers in one go to ensure rebuilds
    markers.assignAll(newMarkers);
  }

  HotelModel _toHotelModel(Property p) {
    return HotelModel(
      id: p.id.toString(),
      name: p.name,
      imageUrl: p.displayImage,
      price: p.pricePerNight,
      rating: p.rating ?? 0,
      position: LatLng(
        p.latitude ?? currentLocation.value.latitude,
        p.longitude ?? currentLocation.value.longitude,
      ),
      description: p.description ?? '${p.propertyType} in ${p.city}',
    );
  }

  void _showHotelDetails(HotelModel hotel) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600], size: 16),
                      Text(' ${hotel.rating} • ₹${hotel.price}/night'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(hotel.description),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.toNamed('/listing/${hotel.id}');
                      },
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  Future<void> _searchAutocomplete(String q) async {
    if ((q).trim().isEmpty || _placesService == null) {
      predictions.clear();
      return;
    }
    isSearching.value = true;
    try {
      final results = await _placesService!.autocomplete(
        q,
        lat: _locationService?.latitude ?? currentLocation.value.latitude,
        lng: _locationService?.longitude ?? currentLocation.value.longitude,
      );
      predictions.assignAll(results);
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> selectPrediction(PlacePrediction p) async {
    if (_placesService == null) return;
    isLoadingLocation.value = true;
    try {
      final details = await _placesService!.details(p.placeId);
      if (details == null) return;
      final newLoc = LatLng(details.lat, details.lng);
      // Update global location selection for consistency
      _locationService?.setSelectedLocation(
        lat: details.lat,
        lng: details.lng,
        locationName: details.name,
      );
      searchController.text = details.name;
      predictions.clear();
      currentLocation.value = newLoc;
      mapController.move(newLoc, 12);
      await _loadHotelsNearLocation(newLoc);
    } finally {
      isLoadingLocation.value = false;
    }
  }

  Future<void> onSearchSubmitted(String query) async {
    if (predictions.isNotEmpty) {
      await selectPrediction(predictions.first);
      return;
    }
    // If no predictions yet, trigger autocomplete and pick first if any
    await _searchAutocomplete(query);
    if (predictions.isNotEmpty) {
      await selectPrediction(predictions.first);
    }
  }
}
