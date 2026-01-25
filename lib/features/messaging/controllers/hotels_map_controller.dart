import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/services/places_service.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/data/models/unified_filter_model.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/utils/helpers/currency_helper.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';

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
  late flutter_map.MapController mapController;
  late final PageController cardsController;
  final RxList<flutter_map.Marker> markers = <flutter_map.Marker>[].obs;
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
  final RxString locationLabel = ''.obs;
  PropertiesRepository? _propertiesService;
  PlacesService? _placesService;
  LocationService? _locationService;
  FilterController? _filterController;
  UnifiedFilterModel _activeFilters = UnifiedFilterModel.empty;
  Worker? _filterWorker;
  Worker? _locationWorker;
  Worker? _searchWorker;
  final List<HotelModel> _allHotels = [];
  double _lastRadius = 10;
  double _lastMapZoom = 12;
  StreamSubscription<flutter_map.MapEvent>? _mapEventSub;
  bool _mapReady = false;
  LatLng? _pendingCameraCenter;
  double? _pendingCameraZoom;

  @override
  void onInit() {
    super.onInit();
    mapController = flutter_map.MapController();
    cardsController = PageController(viewportFraction: 0.72);
    _mapReady = false;
    _pendingCameraCenter = null;
    _pendingCameraZoom = null;
    _mapEventSub = mapController.mapEventStream.listen((event) {
      _lastMapZoom = event.camera.zoom;
    });
    try {
      _propertiesService = Get.find<PropertiesRepository>();
    } catch (_) {}
    try {
      _placesService = Get.find<PlacesService>();
    } catch (_) {}
    _bindLocationService();
    _searchWorker = debounce<String>(
      searchQuery,
      (q) => _searchAutocomplete(q),
      time: const Duration(milliseconds: 250),
    );
    _initializeFilterSync();
    _requestLocationPermission();
    _refreshLocationLabel();
  }

  @override
  void onClose() {
    _mapEventSub?.cancel();
    cardsController.dispose();
    searchController.dispose();
    _filterWorker?.dispose();
    _locationWorker?.dispose();
    _searchWorker?.dispose();
    _mapReady = false;
    _pendingCameraCenter = null;
    _pendingCameraZoom = null;
    super.onClose();
  }

  void onMapReady() {
    if (_mapReady) return;
    _mapReady = true;
    final pendingCenter = _pendingCameraCenter;
    final pendingZoom = _pendingCameraZoom;
    _pendingCameraCenter = null;
    _pendingCameraZoom = null;
    if (pendingCenter != null && pendingZoom != null) {
      _moveMapTo(pendingCenter, pendingZoom);
    }
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
    _moveMapTo(hotel.position, _lastMapZoom);
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

  double get activeRadiusKm => _activeFilters.radiusKm ?? _lastRadius;

  void zoomIn() {
    final camera = mapController.camera;
    final zoom = (camera.zoom + 0.5).clamp(5.0, 18.0);
    _moveMapTo(camera.center, zoom);
  }

  void zoomOut() {
    final camera = mapController.camera;
    final zoom = (camera.zoom - 0.5).clamp(3.0, 18.0);
    _moveMapTo(camera.center, zoom);
  }

  Future<void> getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppSnackbar.error(
          title: 'Location Error',
          message: 'Location services are disabled',
        );
        _loadSampleHotels();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppSnackbar.warning(
            title: 'Permission Denied',
            message: 'Location permission is required to show nearby hotels',
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

      _moveMapTo(currentLocation.value, 12);

      await _loadHotelsNearLocation(currentLocation.value);
    } catch (e) {
      AppSnackbar.error(
        title: 'Error',
        message: 'Failed to get current location: $e',
      );
      _loadSampleHotels();
    } finally {
      isLoadingLocation.value = false;
      _refreshLocationLabel();
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
      _refreshLocationLabel();
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
    final List<flutter_map.Marker> newMarkers = hotels.map((hotel) {
      final isSelected = selectedId == hotel.id;
      final theme = Get.theme;
      final colorScheme = theme.colorScheme;
      final badgeColor = isSelected ? colorScheme.primary : colorScheme.surface;
      final textColor = isSelected
          ? colorScheme.onPrimary
          : colorScheme.primary;
      final borderColor = isSelected
          ? colorScheme.primary
          : colorScheme.primary.withValues(alpha: 0.5);
      final shadowColor = Colors.black.withValues(
        alpha: isSelected ? 0.28 : 0.14,
      );
      return flutter_map.Marker(
        width: 96.0,
        height: isSelected ? 92.0 : 84.0,
        point: hotel.position,
        child: GestureDetector(
          onTap: () => onMarkerTapped(hotel),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor, width: 1.6),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: isSelected ? 14 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  CurrencyHelper.formatCompact(hotel.price),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: isSelected ? 16 : 14,
                height: isSelected ? 16 : 14,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(
                        alpha: isSelected ? 0.45 : 0.25,
                      ),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
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

  void _bindLocationService() {
    if (Get.isRegistered<LocationService>()) {
      _locationService = Get.find<LocationService>();
      _locationWorker = ever<String>(
        _locationService!.locationNameRx,
        (value) => _refreshLocationLabel(value),
      );
    }
  }

  void _refreshLocationLabel([String? candidate]) {
    locationLabel.value = _buildLocationLabel(candidate);
  }

  String _buildLocationLabel([String? candidate]) {
    final value =
        candidate ?? _locationService?.locationName ?? searchController.text;
    if (value.trim().isNotEmpty) {
      return value.trim();
    }
    return 'Select location';
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
      _refreshLocationLabel(details.name);
      predictions.clear();
      currentLocation.value = newLoc;
      _moveMapTo(newLoc, 12);
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

  void _moveMapTo(LatLng target, double zoom) {
    _lastMapZoom = zoom;
    if (!_mapReady) {
      _pendingCameraCenter = target;
      _pendingCameraZoom = zoom;
      return;
    }
    mapController.move(target, zoom);
  }
}
