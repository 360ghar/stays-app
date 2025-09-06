import 'package:get/get.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/models/property_image_model.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/data/services/properties_service.dart';
import 'package:stays_app/app/data/services/wishlist_service.dart';

class ExploreController extends GetxController with GetTickerProviderStateMixin {
  LocationService? _locationService;
  PropertiesService? _propertiesService;
  WishlistService? _wishlistService;
  
  final RxList<Property> popularHomes = <Property>[].obs;
  final RxList<Property> nearbyHotels = <Property>[].obs;
  final RxList<Property> recommendedHotels = <Property>[].obs;
  final RxSet<int> favoritePropertyIds = <int>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString errorMessage = ''.obs;
  
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
    _initializeServices();
    _initializeData();
  }

  void _initializeServices() {
    try {
      _locationService = Get.find<LocationService>();
      _listenToLocationChanges();
    } catch (e) {
      print('LocationService not found, using default values');
    }
    
    try {
      _propertiesService = Get.find<PropertiesService>();
    } catch (e) {
      print('PropertiesService not found');
    }
    
    try {
      _wishlistService = Get.find<WishlistService>();
    } catch (e) {
      print('WishlistService not found');
    }
  }

  void _initializeData() {
    loadProperties();
    loadWishlist();
  }

  void _listenToLocationChanges() {
    if (_locationService != null) {
      ever(_locationService!.currentCity.obs, (_) {
        loadProperties();
      });
    }
  }

  Future<void> loadProperties() async {
    if (_propertiesService == null) {
      _loadMockData();
      return;
    }
    
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      // Load popular homes for current city (short stay properties)
      final popularProperties = await _propertiesService!.getShortStayProperties(
        city: currentCity,
        limit: 10,
      );
      popularHomes.value = popularProperties;
      
      // Load nearby properties
      if (_locationService?.latitude != null && _locationService?.longitude != null) {
        final nearby = await _propertiesService!.getNearbyProperties(
          latitude: _locationService!.latitude!,
          longitude: _locationService!.longitude!,
          propertyType: 'short_stay',
          radiusKm: 50,
          limit: 10,
        );
        nearbyHotels.value = nearby;
      } else {
        // Fallback to loading by nearby city
        final nearby = await _propertiesService!.getShortStayProperties(
          city: nearbyCity,
          limit: 10,
        );
        nearbyHotels.value = nearby;
      }
      
      // Load recommended properties
      try {
        final recommended = await _propertiesService!.getRecommendedProperties(
          limit: 8,
        );
        recommendedHotels.value = recommended;
      } catch (e) {
        // If recommendations endpoint fails, use a mix of popular and nearby
        final recommended = <Property>[];
        if (popularHomes.isNotEmpty) recommended.add(popularHomes[0]);
        if (nearbyHotels.isNotEmpty) recommended.add(nearbyHotels[0]);
        if (popularHomes.length > 2) recommended.add(popularHomes[2]);
        if (nearbyHotels.length > 3) recommended.add(nearbyHotels[3]);
        recommendedHotels.value = recommended;
      }
      
    } catch (e) {
      errorMessage.value = 'Failed to load properties. Please try again.';
      print('Error loading properties: $e');
      // Load mock data as fallback
      _loadMockData();
    } finally {
      isLoading.value = false;
    }
  }
  
  void _loadMockData() {
    isLoading.value = true;
    
    // Create mock properties from old Hotel model data
    final mockProperties = _createMockProperties(currentCity);
    popularHomes.value = mockProperties;
    
    final nearbyMock = _createMockProperties(nearbyCity);
    nearbyHotels.value = nearbyMock;
    
    // Mix for recommendations
    final recommended = <Property>[];
    if (popularHomes.isNotEmpty) recommended.add(popularHomes[0]);
    if (nearbyHotels.isNotEmpty) recommended.add(nearbyHotels[0]);
    if (popularHomes.length > 2) recommended.add(popularHomes[2]);
    if (nearbyHotels.length > 3) recommended.add(nearbyHotels[3]);
    recommendedHotels.value = recommended;
    
    isLoading.value = false;
  }
  
  List<Property> _createMockProperties(String city) {
    return [
      Property(
        id: 1,
        name: 'The Grand Plaza',
        images: [
          PropertyImage(
            id: 1,
            propertyId: 1,
            imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945',
            displayOrder: 1,
            isMainImage: true,
          ),
        ],
        city: city,
        country: 'USA',
        rating: 4.8,
        reviewsCount: 1254,
        pricePerNight: 289,
        propertyType: 'Luxury Hotel',
        amenities: ['WiFi', 'Pool', 'Gym', 'Spa', 'Restaurant'],
        description: 'Experience luxury at its finest in the heart of $city.',
      ),
      Property(
        id: 2,
        name: 'Sunset Boutique Hotel',
        images: [
          PropertyImage(
            id: 2,
            propertyId: 2,
            imageUrl: 'https://images.unsplash.com/photo-1582719508461-905c673771fd',
            displayOrder: 1,
            isMainImage: true,
          ),
        ],
        city: city,
        country: 'USA',
        rating: 4.6,
        reviewsCount: 892,
        pricePerNight: 195,
        propertyType: 'Boutique Hotel',
        amenities: ['WiFi', 'Breakfast', 'Bar', 'Parking'],
        description: 'Charming boutique hotel with stunning sunset views.',
      ),
      Property(
        id: 3,
        name: 'Urban Comfort Suites',
        images: [
          PropertyImage(
            id: 3,
            propertyId: 3,
            imageUrl: 'https://images.unsplash.com/photo-1564501049412-61c2a3083791',
            displayOrder: 1,
            isMainImage: true,
          ),
        ],
        city: city,
        country: 'USA',
        rating: 4.5,
        reviewsCount: 678,
        pricePerNight: 145,
        propertyType: 'Hotel Suite',
        amenities: ['WiFi', 'Kitchen', 'Gym', 'Business Center'],
        description: 'Modern suites perfect for business and leisure.',
      ),
    ];
  }
  
  Future<void> loadWishlist() async {
    if (_wishlistService == null) return;
    
    try {
      final wishlistItems = await _wishlistService!.getUserWishlist();
      favoritePropertyIds.clear();
      favoritePropertyIds.addAll(wishlistItems
          .map((item) => item.propertyId));
    } catch (e) {
      print('Error loading wishlist: $e');
    }
  }

  Future<void> refreshLocation() async {
    if (_locationService != null) {
      await _locationService!.updateLocation();
    }
    await loadProperties();
  }
  
  @override
  Future<void> refresh() async {
    await Future.wait([
      loadProperties(),
      loadWishlist(),
    ]);
  }

  void navigateToSearch() {
    Get.toNamed('/search');
  }

  void navigateToPropertyDetail(Property property) {
    Get.toNamed('/listing/${property.id}', arguments: property);
  }

  void navigateToAllProperties(String city) {
    final propertyList = city == currentCity ? popularHomes : nearbyHotels;
    Get.toNamed('/search-results', arguments: {
      'city': city,
      'properties': propertyList.toList(),
    });
  }

  Future<void> toggleFavorite(Property property) async {
    final propertyId = property.id;
    final isCurrentlyFavorite = favoritePropertyIds.contains(propertyId);
    
    if (_wishlistService == null) {
      // Local toggle if service not available
      if (isCurrentlyFavorite) {
        favoritePropertyIds.remove(propertyId);
      } else {
        favoritePropertyIds.add(propertyId);
      }
      _updatePropertyFavoriteStatus(propertyId, !isCurrentlyFavorite);
      return;
    }
    
    try {
      bool success;
      if (isCurrentlyFavorite) {
        success = await _wishlistService!.removeFromWishlist(
          propertyId: propertyId,
        );
        if (success) {
          favoritePropertyIds.remove(propertyId);
          Get.snackbar(
            'Removed from Wishlist',
            '${property.name} has been removed from your wishlist',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        success = await _wishlistService!.addToWishlist(
          propertyId: propertyId,
        );
        if (success) {
          favoritePropertyIds.add(propertyId);
          Get.snackbar(
            'Added to Wishlist',
            '${property.name} has been added to your wishlist',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 2),
          );
        }
      }
      
      if (success) {
        _updatePropertyFavoriteStatus(propertyId, !isCurrentlyFavorite);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      Get.snackbar(
        'Error',
        'Failed to update wishlist. Please try again.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }
  
  void _updatePropertyFavoriteStatus(int propertyId, bool isFavorite) {
    // Update in popular homes
    final popularIndex = popularHomes.indexWhere((p) => p.id == propertyId);
    if (popularIndex != -1) {
      popularHomes[popularIndex] = popularHomes[popularIndex].copyWith(
        isFavorite: isFavorite,
      );
    }
    
    // Update in nearby hotels
    final nearbyIndex = nearbyHotels.indexWhere((p) => p.id == propertyId);
    if (nearbyIndex != -1) {
      nearbyHotels[nearbyIndex] = nearbyHotels[nearbyIndex].copyWith(
        isFavorite: isFavorite,
      );
    }
    
    // Update in recommended
    final recommendedIndex = recommendedHotels.indexWhere((p) => p.id == propertyId);
    if (recommendedIndex != -1) {
      recommendedHotels[recommendedIndex] = recommendedHotels[recommendedIndex].copyWith(
        isFavorite: isFavorite,
      );
    }
  }
  
  bool isPropertyFavorite(int propertyId) {
    return favoritePropertyIds.contains(propertyId);
  }
}