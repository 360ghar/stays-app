import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class LocationService {
  factory LocationService() => _shared;
  LocationService._internal() {
    _readyCompleter = Completer<void>();
    unawaited(_initLocationService());
  }

  // Shared instance so the Riverpod graph shares one permission flow and
  // position stream app-wide.
  static final LocationService _shared = LocationService._internal();

  // geocoding 5.x groups all functionality in the Geocoding class.
  final Geocoding _geocoding = Geocoding();
  final ValueNotifier<Position?> _currentPosition =
      ValueNotifier<Position?>(null);
  // Selected location overrides current GPS position for querying backend
  final ValueNotifier<double?> _selectedLat = ValueNotifier<double?>(null);
  final ValueNotifier<double?> _selectedLng = ValueNotifier<double?>(null);
  final ValueNotifier<String> _locationName =
      ValueNotifier<String>(''); // Human-readable name for UI
  final ValueNotifier<String> _currentCity =
      ValueNotifier<String>(''); // City-level name for grouping
  final ValueNotifier<bool> _isLocationEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isLoadingLocation = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isInitialized =
      ValueNotifier<bool>(false); // Track if location has been initialized
  Completer<void>? _readyCompleter;

  Position? get currentPosition => _currentPosition.value;
  // UI-friendly name of location to display
  String get locationName => _locationName.value;
  // City-level name derived from geocoding
  String get currentCity => _currentCity.value;
  bool get isLocationEnabled => _isLocationEnabled.value;
  bool get isLoadingLocation => _isLoadingLocation.value;
  bool get isInitialized => _isInitialized.value;
  double? get latitude =>
      _selectedLat.value ?? _currentPosition.value?.latitude;
  double? get longitude =>
      _selectedLng.value ?? _currentPosition.value?.longitude;

  /// Completes when the location service has finished its initial setup.
  /// Callers can `await locationService.ready` instead of busy-wait polling.
  Future<void> get ready => _readyCompleter?.future ?? Future.value();

  void dispose() {
    _currentPosition.dispose();
    _selectedLat.dispose();
    _selectedLng.dispose();
    _locationName.dispose();
    _currentCity.dispose();
    _isLocationEnabled.dispose();
    _isLoadingLocation.dispose();
    _isInitialized.dispose();
  }

  Future<void> _initLocationService() async {
    try {
      await checkLocationPermission();
    } finally {
      _isInitialized.value = true;
      _readyCompleter?.complete();
      AppLogger.info('LocationService initialization completed');
    }
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

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning(
          'Location services disabled; skipping precise recommendations',
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
        AppLogger.warning(
          'Location permission permanently denied; using last known area',
        );
        return null;
      }

      if (ensurePrecise) {
        await _ensurePreciseAccuracyIfPossible();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(),
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
      final List<Placemark> placemarks = await _geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude);

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
    unawaited(_updateCityFromCoordinates(lat, lng));
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
      final placemarks = await _geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        _currentCity.value = _deriveCityFromPlacemark(placemarks[0]);
      }
    } catch (e) {
      AppLogger.warning('Failed to resolve city from coordinates', e);
    }
  }
}
