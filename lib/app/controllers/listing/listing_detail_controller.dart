import 'package:get/get.dart';

import '../../data/repositories/listing_repository.dart';
import '../../data/models/listing_model.dart';

class ListingDetailController extends GetxController {
  final ListingRepository _repository;
  ListingDetailController({required ListingRepository repository}) : _repository = repository;

  final Rxn<ListingModel> listing = Rxn<ListingModel>();
  final RxBool isLoading = false.obs;

  Future<void> load(String id) async {
    try {
      isLoading.value = true;
      listing.value = await _repository.getListingById(id);
    } finally {
      isLoading.value = false;
    }
  }
}
