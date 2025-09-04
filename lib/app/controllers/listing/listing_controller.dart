import 'package:get/get.dart';

import '../../data/repositories/listing_repository.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/location_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/hotel_model.dart';
import '../../data/models/amenity_model.dart';

class ListingController extends GetxController {
  final ListingRepository _repository;
  ListingController({required ListingRepository repository}) : _repository = repository;

  final RxList<ListingModel> listings = <ListingModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initFromArgumentsOrFetch();
  }

  void _initFromArgumentsOrFetch() {
    try {
      final args = Get.arguments;
      if (args is Map && args['hotels'] is List) {
        final rawList = args['hotels'] as List;
        final hotels = rawList.whereType<Hotel>().toList();
        if (hotels.isNotEmpty) {
          listings.assignAll(_mapHotelsToListings(hotels));
          return;
        }
      }
    } catch (_) {
      // If anything goes wrong, fall back to repository fetch
    }
    fetch();
  }

  List<ListingModel> _mapHotelsToListings(List<Hotel> hotels) {
    PropertyType _mapPropertyType(String value) {
      switch (value.toLowerCase()) {
        case 'house':
          return PropertyType.house;
        case 'villa':
          return PropertyType.villa;
        case 'condo':
          return PropertyType.condo;
        default:
          return PropertyType.apartment;
      }
    }

    return hotels.map((h) {
      final amenities = (h.amenities ?? [])
          .map((name) => AmenityModel(key: name.toLowerCase().replaceAll(' ', '_'), name: name))
          .toList();

      return ListingModel(
        id: h.id,
        title: h.name,
        description: h.description ?? '${h.propertyType} in ${h.city}',
        propertyType: _mapPropertyType(h.propertyType),
        location: LocationModel(
          city: h.city,
          country: h.country,
          lat: h.latitude ?? 0,
          lng: h.longitude ?? 0,
        ),
        pricePerNight: h.pricePerNight,
        images: [h.imageUrl],
        amenities: amenities,
        host: const UserModel(id: 'mock', email: 'host@stays.app'),
        maxGuests: 2,
        bedrooms: 1,
        bathrooms: 1,
        rating: h.rating,
        reviewCount: h.reviews,
        houseRules: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  Future<void> fetch() async {
    try {
      isLoading.value = true;
      final data = await _repository.getListings(filters: {});
      listings.assignAll(data);
    } catch (_) {
      // Fallback sample to render UI when API not available
      listings.assignAll([
        ListingModel(
          id: '1',
          title: 'Cozy Studio in City Center',
          description: 'Walk to cafes and museums from this modern studio.',
          propertyType: PropertyType.apartment,
          location: const LocationModel(city: 'New York', country: 'USA', lat: 0, lng: 0),
          pricePerNight: 120,
          images: const [],
          amenities: const [],
          host: const UserModel(id: 'h1', email: 'host@example.com'),
          maxGuests: 2,
          bedrooms: 1,
          bathrooms: 1,
          rating: 4.7,
          reviewCount: 32,
          houseRules: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);
    } finally {
      isLoading.value = false;
    }
  }
}
