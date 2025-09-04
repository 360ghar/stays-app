import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService extends GetxService {
  final _currentPosition = Rxn<Position>();
  final _currentCity = ''.obs;
  final _nearbyCity = ''.obs;
  final _isLocationEnabled = false.obs;
  final _isLoadingLocation = false.obs;

  Position? get currentPosition => _currentPosition.value;
  String get currentCity => _currentCity.value;
  String get nearbyCity => _nearbyCity.value;
  bool get isLocationEnabled => _isLocationEnabled.value;
  bool get isLoadingLocation => _isLoadingLocation.value;

  @override
  void onInit() {
    super.onInit();
    _initLocationService();
  }

  void _initLocationService() async {
    await checkLocationPermission();
  }

  Future<bool> checkLocationPermission() async {
    try {
      _isLoadingLocation.value = true;
      
      final status = await Permission.location.status;
      
      if (status.isGranted) {
        await getCurrentLocation();
        _isLocationEnabled.value = true;
        return true;
      } else if (status.isDenied) {
        final result = await Permission.location.request();
        if (result.isGranted) {
          await getCurrentLocation();
          _isLocationEnabled.value = true;
          return true;
        }
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      
      _isLocationEnabled.value = false;
      return false;
    } catch (e) {
      print('Error checking location permission: $e');
      _isLocationEnabled.value = false;
      return false;
    } finally {
      _isLoadingLocation.value = false;
    }
  }

  Future<Position?> getCurrentLocation() async {
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      _currentPosition.value = position;
      await _getCityFromPosition(position);
      
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      _setDefaultCities();
      return null;
    } finally {
      _isLoadingLocation.value = false;
    }
  }

  Future<void> _getCityFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        _currentCity.value = place.locality ?? place.subAdministrativeArea ?? 'Unknown';
        
        // Get nearby city (mock for now, in real app would query nearby cities)
        _nearbyCity.value = _getNearbyCity(place.locality ?? '');
      } else {
        _setDefaultCities();
      }
    } catch (e) {
      print('Error getting city from position: $e');
      _setDefaultCities();
    }
  }

  String _getNearbyCity(String currentCity) {
    // Mock nearby city logic - in production, this would query actual nearby cities
    final nearbyCities = {
      'New York': 'Newark',
      'Los Angeles': 'Long Beach',
      'Chicago': 'Milwaukee',
      'Houston': 'Austin',
      'Phoenix': 'Tucson',
      'San Francisco': 'San Jose',
      'London': 'Brighton',
      'Paris': 'Versailles',
      'Tokyo': 'Yokohama',
      'Sydney': 'Melbourne',
      'Mumbai': 'Pune',
      'Delhi': 'Gurgaon',
      'Bangalore': 'Mysore',
    };
    
    return nearbyCities[currentCity] ?? 'Nearby City';
  }

  void _setDefaultCities() {
    _currentCity.value = 'New York';
    _nearbyCity.value = 'Newark';
  }

  Future<void> updateLocation() async {
    await getCurrentLocation();
  }
}