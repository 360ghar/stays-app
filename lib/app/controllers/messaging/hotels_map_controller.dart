import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final Rx<LatLng> currentLocation = const LatLng(28.6139, 77.2090).obs; // Delhi default
  final RxString searchQuery = ''.obs;
  final RxBool isLoadingLocation = false.obs;
  final RxBool isLoadingHotels = false.obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    mapController = MapController();
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
          Get.snackbar('Permission Denied', 'Location permission is required to show nearby hotels');
          _loadSampleHotels();
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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
    
    // Simulate API call - replace with actual hotel API integration
    await Future.delayed(const Duration(seconds: 1));
    
    final sampleHotels = [
      HotelModel(
        id: '1',
        name: 'Grand Palace Hotel',
        imageUrl: 'https://via.placeholder.com/300x200',
        price: 120.0,
        rating: 4.5,
        position: LatLng(location.latitude + 0.01, location.longitude + 0.01),
        description: 'Luxury hotel with premium amenities',
      ),
      HotelModel(
        id: '2',
        name: 'City Center Inn',
        imageUrl: 'https://via.placeholder.com/300x200',
        price: 80.0,
        rating: 4.2,
        position: LatLng(location.latitude - 0.01, location.longitude + 0.01),
        description: 'Comfortable stay in the heart of the city',
      ),
      HotelModel(
        id: '3',
        name: 'Boutique Suites',
        imageUrl: 'https://via.placeholder.com/300x200',
        price: 200.0,
        rating: 4.8,
        position: LatLng(location.latitude + 0.01, location.longitude - 0.01),
        description: 'Stylish suites with modern design',
      ),
      HotelModel(
        id: '4',
        name: 'Budget Stay',
        imageUrl: 'https://via.placeholder.com/300x200',
        price: 50.0,
        rating: 3.9,
        position: LatLng(location.latitude - 0.01, location.longitude - 0.01),
        description: 'Affordable accommodation with basic amenities',
      ),
    ];

    hotels.assignAll(sampleHotels);
    _updateMapMarkers();
    isLoadingHotels.value = false;
  }

  void _loadSampleHotels() {
    // Load sample data for Delhi
    _loadHotelsNearLocation(currentLocation.value);
  }

  void _updateMapMarkers() {
    markers.clear();
    
    for (final hotel in hotels) {
      markers.add(
        Marker(
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
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '\$${hotel.price.toInt()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      );
    }
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
                      Text(' ${hotel.rating} • \$${hotel.price}/night'),
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


  Future<void> searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      isLoadingLocation.value = true;
      List<Location> locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        final newLocation = LatLng(location.latitude, location.longitude);
        
        currentLocation.value = newLocation;
        mapController.move(newLocation, 12);
        
        await _loadHotelsNearLocation(newLocation);
      } else {
        Get.snackbar('Not Found', 'Location not found. Please try a different search term.');
      }
    } catch (e) {
      Get.snackbar('Search Error', 'Failed to search location: $e');
    } finally {
      isLoadingLocation.value = false;
    }
  }

  void onSearchSubmitted(String query) {
    searchQuery.value = query;
    searchLocation(query);
  }
}