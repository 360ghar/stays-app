import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class LocationService extends GetxService {
  final _currentPosition = Rxn<Position>();
  // Selected location overrides current GPS position for querying backend
  final RxnDouble _selectedLat = RxnDouble();
  final RxnDouble _selectedLng = RxnDouble();
  final RxString _locationName = ''.obs; // Human-readable name for UI
  final RxString _currentCity = ''.obs; // City-level name for grouping
  final _isLocationEnabled = false.obs;
  final _isLoadingLocation = false.obs;
  final RxBool _isInitialized = false.obs; // Track if location has been initialized

  Position? get currentPosition => _currentPosition.value;
  // UI-friendly name of location to display
  String get locationName => _locationName.value;
  RxString get locationNameRx => _locationName;
  // City-level name derived from geocoding
  String get currentCity => _currentCity.value;
  RxString get currentCityRx => _currentCity;
  bool get isLocationEnabled => _isLocationEnabled.value;
  bool get isLoadingLocation => _isLoadingLocation.value;
  bool get isInitialized => _isInitialized.value;
  double? get latitude =>
      _selectedLat.value ?? _currentPosition.value?.latitude;
  double? get longitude =>
      _selectedLng.value ?? _currentPosition.value?.longitude;

  @override
  void onInit() {
    super.onInit();
    _initLocationService();
  }

  void _initLocationService() async {
    await checkLocationPermission();
    _isInitialized.value = true;
    AppLogger.info('LocationService initialization completed');
  }

  Future<bool> checkLocationPermission() async {
    try {
      _isLoadingLocation.value = true;

      final status = await Permission.location.status;

      if (status.isGranted) {
        await getCurrentLocation(ensurePrecise: true);
        _isLocationEnabled.value = true;
        return true;
      } else if (status.isDenied) {
        final result = await Permission.location.request();
        if (result.isGranted) {
          await getCurrentLocation(ensurePrecise: true);
          _isLocationEnabled.value = true;
          return true;
        }
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }

      _isLocationEnabled.value = false;
      return false;
    } catch (e) {
      AppLogger.error('Error checking location permission', e);
      _isLocationEnabled.value = false;
      return false;
    } finally {
      _isLoadingLocation.value = false;
    }
  }

  Future<Position?> getCurrentLocation({bool ensurePrecise = false}) async {
    try {
      _isLoadingLocation.value = true;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Services',
          'Please enable location services to get better recommendations',
          snackPosition: SnackPosition.TOP,
        );
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Location Permission',
          'Location permissions are permanently denied, please enable from settings',
          snackPosition: SnackPosition.TOP,
        );
        return null;
      }

      if (ensurePrecise) {
        await _ensurePreciseAccuracyIfPossible();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      _currentPosition.value = position;
      await _updateLocationNameFromPosition(position);

      return position;
    } catch (e) {
      AppLogger.error('Error getting current location', e);
      _setDefaultLocation();
      return null;
    } finally {
      _isLoadingLocation.value = false;
    }
  }

  Future<void> _ensurePreciseAccuracyIfPossible() async {
    try {
      // Check if iOS has Reduced Accuracy enabled and request temporary full accuracy if possible
      final status = await Geolocator.getLocationAccuracy();
      if (status == LocationAccuracyStatus.reduced) {
        // Requires NSLocationTemporaryUsageDescriptionDictionary with key below in Info.plist
        await Geolocator.requestTemporaryFullAccuracy(
          purposeKey: 'PreciseLocation',
        );
      }
    } catch (_) {
      // Ignore if not supported (Android or older iOS); continue with best available
    }
  }

  Future<void> _updateLocationNameFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        // Compose a friendly location name: subLocality, locality or administrative area
        final parts = <String?>[
          place.subLocality,
          place.locality,
          if ((place.locality == null || place.locality!.isEmpty) &&
              (place.subAdministrativeArea != null &&
                  place.subAdministrativeArea!.isNotEmpty))
            place.subAdministrativeArea,
        ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
        _locationName.value = parts.isNotEmpty
            ? parts.join(', ')
            : (place.administrativeArea ?? 'Unknown');

        // Update city-level name for grouping
        _currentCity.value = _deriveCityFromPlacemark(place);
      } else {
        _setDefaultLocation();
      }
    } catch (e) {
      AppLogger.error('Error reverse geocoding position', e);
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    _locationName.value = 'Your area';
    _currentCity.value = '';
  }

  Future<void> updateLocation({bool ensurePrecise = false}) async {
    await getCurrentLocation(ensurePrecise: ensurePrecise);
  }

  // Set a user-selected location (from Google Places)
  void setSelectedLocation({
    required double lat,
    required double lng,
    required String locationName,
  }) {
    _selectedLat.value = lat;
    _selectedLng.value = lng;
    _locationName.value = locationName;
    // Best-effort: resolve and update city in background
    _updateCityFromCoordinates(lat, lng);
  }

  // Clear manual selection so queries use current GPS location
  void clearSelectedLocation() {
    _selectedLat.value = null;
    _selectedLng.value = null;
  }

  String _deriveCityFromPlacemark(Placemark place) {
    return [
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
        ]
        .whereType<String>()
        .map((e) => e.trim())
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');
  }

  Future<void> _updateCityFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        _currentCity.value = _deriveCityFromPlacemark(placemarks[0]);
      }
    } catch (e) {
      AppLogger.warning('Failed to resolve city from coordinates', e);
    }
  }
}
