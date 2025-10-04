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
import '../../data/models/unified_filter_model.dart';
import '../filter_controller.dart';
import '../../utils/helpers/currency_helper.dart';

class HotelModel {
  final Property property;
  final LatLng position;
  final double distanceKm;

  HotelModel({
    required this.property,
    required this.position,
    this.distanceKm = 0,
  });

  String get id => property.id.toString();
  String get name => property.name;
  double get price => property.pricePerNight;
  double get rating => property.rating ?? 0;
  String? get imageUrl => property.displayImage;
  String get description =>
      property.description ??
      '${property.propertyTypeDisplay} · ${property.city}';
  String get propertyType => property.propertyType.toLowerCase();
}

class HotelsMapController extends GetxController {
  late MapController mapController;
  late final PageController cardsController;
  final RxList<Marker> markers = <Marker>[].obs;
  final RxList<HotelModel> hotels = <HotelModel>[].obs;
  final Rx<LatLng> currentLocation = const LatLng(
    28.6139,
    77.2090,
  ).obs; // Delhi default
  final RxnString selectedHotelId = RxnString();
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxList<PlacePrediction> predictions = <PlacePrediction>[].obs;
  final RxBool isLoadingLocation = false.obs;
  final RxBool isLoadingHotels = false.obs;
  final searchController = TextEditingController();
  PropertiesRepository? _propertiesService;
  PlacesService? _placesService;
  LocationService? _locationService;
  FilterController? _filterController;
  UnifiedFilterModel _activeFilters = UnifiedFilterModel.empty;
  Worker? _filterWorker;
  final List<HotelModel> _allHotels = [];
  double _lastRadius = 10;
  double _lastMapZoom = 12;
  StreamSubscription<MapEvent>? _mapEventSub;

  @override
  void onInit() {
    super.onInit();
    mapController = MapController();
    cardsController = PageController(viewportFraction: 0.88);
    _mapEventSub = mapController.mapEventStream.listen((event) {
      _lastMapZoom = event.camera.zoom;
    });
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
    _initializeFilterSync();
    _requestLocationPermission();
  }

  @override
  void onClose() {
    _mapEventSub?.cancel();
    cardsController.dispose();
    searchController.dispose();
    _filterWorker?.dispose();
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

  void _initializeFilterSync() {
    if (!Get.isRegistered<FilterController>()) return;
    _filterController = Get.find<FilterController>();
    _activeFilters = _filterController!.filterFor(FilterScope.locate);
    _filterWorker = debounce<UnifiedFilterModel>(
      _filterController!.rxFor(FilterScope.locate),
      (filters) {
        if (_activeFilters == filters) return;
        _activeFilters = filters;
        _applyFilters();
      },
      time: const Duration(milliseconds: 150),
    );
  }

  void _applyFilters({bool fromRemoteFetch = false}) {
    final desiredRadius = _activeFilters.radiusKm ?? 10;
    if (!fromRemoteFetch && (_lastRadius - desiredRadius).abs() > 0.5) {
      _loadHotelsNearLocation(currentLocation.value, radiusKm: desiredRadius);
      return;
    }
    if (_allHotels.isEmpty) {
      _setHotels(const <HotelModel>[]);
      return;
    }
    if (_activeFilters.isEmpty) {
      _setHotels(List<HotelModel>.from(_allHotels));
    } else {
      final filtered = _allHotels
          .where(
            (hotel) => _activeFilters.matchesHotel(
              price: hotel.price,
              rating: hotel.rating,
              propertyType: hotel.propertyType,
            ),
          )
          .toList();
      _setHotels(filtered);
    }
  }

  void _setHotels(List<HotelModel> newHotels) {
    hotels.assignAll(newHotels);
    if (newHotels.isEmpty) {
      selectedHotelId.value = null;
      markers.clear();
      return;
    }

    final currentId = selectedHotelId.value;
    var targetIndex = currentId != null
        ? hotels.indexWhere((hotel) => hotel.id == currentId)
        : -1;
    if (targetIndex == -1 && hotels.isNotEmpty) {
      targetIndex = 0;
      selectedHotelId.value = hotels.first.id;
      _centerOnHotel(hotels.first);
    }

    if (targetIndex >= 0) {
      _jumpToCard(targetIndex);
    }

    _updateMapMarkers();
  }

  void _jumpToCard(int index, {bool animate = false}) {
    if (index < 0 || index >= hotels.length) return;
    Future.microtask(() {
      if (!cardsController.hasClients) return;
      if (animate) {
        cardsController.animateToPage(
          index,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else {
        cardsController.jumpToPage(index);
      }
    });
  }

  void _centerOnHotel(HotelModel hotel) {
    final zoom = _lastMapZoom;
    mapController.move(hotel.position, zoom);
    _lastMapZoom = zoom;
  }

  void selectHotel(int index, {bool syncPage = true, bool syncMap = true}) {
    if (index < 0 || index >= hotels.length) return;
    final hotel = hotels[index];
    final alreadySelected = selectedHotelId.value == hotel.id;
    if (alreadySelected) {
      if (syncMap) {
        _centerOnHotel(hotel);
      }
      return;
    }

    selectedHotelId.value = hotel.id;

    if (syncPage) {
      _jumpToCard(index, animate: true);
    }

    if (syncMap) {
      _centerOnHotel(hotel);
    }

    _updateMapMarkers();
  }

  void onMarkerTapped(HotelModel hotel) {
    final index = hotels.indexWhere((item) => item.id == hotel.id);
    if (index == -1) return;
    selectHotel(index, syncPage: true, syncMap: true);
  }

  void onHotelCardChanged(int index) {
    selectHotel(index, syncPage: false, syncMap: true);
  }

  void openPropertyDetail(HotelModel hotel) {
    Get.toNamed('/listing/${hotel.id}');
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
      _lastMapZoom = 12;

      await _loadHotelsNearLocation(currentLocation.value);
    } catch (e) {
      Get.snackbar('Error', 'Failed to get current location: $e');
      _loadSampleHotels();
    } finally {
      isLoadingLocation.value = false;
    }
  }

  Future<void> _loadHotelsNearLocation(
    LatLng location, {
    double? radiusKm,
  }) async {
    isLoadingHotels.value = true;
    try {
      if (_propertiesService == null) {
        _allHotels.clear();
        _setHotels(const <HotelModel>[]);
        return;
      }
      final double radius = radiusKm ?? _activeFilters.radiusKm ?? _lastRadius;
      final resp = await _propertiesService!.explore(
        lat: location.latitude,
        lng: location.longitude,
        radiusKm: radius,
        limit: 50,
        filters: _activeFilters.toQueryParameters(),
      );
      _lastRadius = radius;
      final mapped = resp.properties.map((p) => _toHotelModel(p)).toList();
      _allHotels
        ..clear()
        ..addAll(mapped);
      _applyFilters(fromRemoteFetch: true);
    } finally {
      isLoadingHotels.value = false;
    }
  }

  void _loadSampleHotels() {
    // Fallback: try to load from current location if service available
    _loadHotelsNearLocation(currentLocation.value);
  }

  void _updateMapMarkers() {
    if (hotels.isEmpty) {
      markers.clear();
      return;
    }

    final selectedId = selectedHotelId.value;
    final List<Marker> newMarkers = hotels.map((hotel) {
      final isSelected = selectedId == hotel.id;
      return Marker(
        width: 100.0,
        height: isSelected ? 100.0 : 90.0,
        point: hotel.position,
        child: GestureDetector(
          onTap: () => onMarkerTapped(hotel),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isSelected ? 0.25 : 0.18,
                      ),
                      blurRadius: isSelected ? 8 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  CurrencyHelper.format(hotel.price),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.location_pin,
                color: isSelected ? Colors.redAccent : Colors.red,
                size: isSelected ? 30 : 24,
              ),
            ],
          ),
        ),
      );
    }).toList();

    markers.assignAll(newMarkers);
  }

  HotelModel _toHotelModel(Property p) {
    final lat = p.latitude ?? currentLocation.value.latitude;
    final lng = p.longitude ?? currentLocation.value.longitude;
    return HotelModel(
      property: p,
      position: LatLng(lat, lng),
      distanceKm: p.distanceKm ?? 0,
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
      _lastMapZoom = 12;
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
