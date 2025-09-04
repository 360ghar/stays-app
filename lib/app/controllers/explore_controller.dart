import 'package:get/get.dart';
import 'package:stays_app/app/data/models/hotel_model.dart';
import 'package:stays_app/app/data/services/location_service.dart';

class ExploreController extends GetxController with GetTickerProviderStateMixin {
  LocationService? _locationService;
  
  final RxList<Hotel> popularHomes = <Hotel>[].obs;
  final RxList<Hotel> nearbyHotels = <Hotel>[].obs;
  final RxList<Hotel> recommendedHotels = <Hotel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  
  String get currentCity {
    return _locationService?.currentCity.isEmpty ?? true 
        ? 'New York' 
        : _locationService!.currentCity;
  }
      
  String get nearbyCity {
    return _locationService?.nearbyCity.isEmpty ?? true 
        ? 'Newark' 
        : _locationService!.nearbyCity;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeLocationService();
    _initializeData();
  }

  void _initializeLocationService() {
    try {
      _locationService = Get.find<LocationService>();
      _listenToLocationChanges();
    } catch (e) {
      print('LocationService not found, using default values');
    }
  }

  void _initializeData() {
    loadHotels();
  }

  void _listenToLocationChanges() {
    if (_locationService != null) {
      ever(_locationService!.currentCity.obs, (_) {
        loadHotels();
      });
    }
  }

  void loadHotels() {
    isLoading.value = true;
    
    // Load popular homes for current city
    popularHomes.value = Hotel.getMockHotels(currentCity);
    
    // Load nearby hotels
    nearbyHotels.value = Hotel.getMockHotels(nearbyCity);
    
    // Load recommended hotels (mix of both)
    final recommended = <Hotel>[];
    if (popularHomes.isNotEmpty) recommended.add(popularHomes[0]);
    if (nearbyHotels.isNotEmpty) recommended.add(nearbyHotels[0]);
    if (popularHomes.length > 2) recommended.add(popularHomes[2]);
    if (nearbyHotels.length > 3) recommended.add(nearbyHotels[3]);
    recommendedHotels.value = recommended;
    
    isLoading.value = false;
  }

  Future<void> refreshLocation() async {
    if (_locationService != null) {
      await _locationService!.updateLocation();
    }
  }

  void navigateToSearch() {
    Get.toNamed('/search');
  }

  void navigateToHotelDetail(Hotel hotel) {
    Get.toNamed('/listing/${hotel.id}', arguments: hotel);
  }

  void navigateToAllHotels(String city) {
    final hotelList = city == currentCity ? popularHomes : nearbyHotels;
    Get.toNamed('/search-results', arguments: {
      'city': city,
      'hotels': hotelList.toList(),
    });
  }

  void toggleFavorite(Hotel hotel) {
    final index = popularHomes.indexWhere((h) => h.id == hotel.id);
    if (index != -1) {
      popularHomes[index] = Hotel(
        id: hotel.id,
        name: hotel.name,
        imageUrl: hotel.imageUrl,
        city: hotel.city,
        country: hotel.country,
        rating: hotel.rating,
        reviews: hotel.reviews,
        pricePerNight: hotel.pricePerNight,
        currency: hotel.currency,
        propertyType: hotel.propertyType,
        isFavorite: !hotel.isFavorite,
        amenities: hotel.amenities,
        description: hotel.description,
      );
    }
    
    final nearbyIndex = nearbyHotels.indexWhere((h) => h.id == hotel.id);
    if (nearbyIndex != -1) {
      nearbyHotels[nearbyIndex] = Hotel(
        id: hotel.id,
        name: hotel.name,
        imageUrl: hotel.imageUrl,
        city: hotel.city,
        country: hotel.country,
        rating: hotel.rating,
        reviews: hotel.reviews,
        pricePerNight: hotel.pricePerNight,
        currency: hotel.currency,
        propertyType: hotel.propertyType,
        isFavorite: !hotel.isFavorite,
        amenities: hotel.amenities,
        description: hotel.description,
      );
    }
  }
}