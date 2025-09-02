import 'package:get/get.dart';

import '../../data/repositories/listing_repository.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/location_model.dart';
import '../../data/models/user_model.dart';

class ListingController extends GetxController {
  final ListingRepository _repository;
  ListingController({required ListingRepository repository}) : _repository = repository;

  final RxList<ListingModel> listings = <ListingModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
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
