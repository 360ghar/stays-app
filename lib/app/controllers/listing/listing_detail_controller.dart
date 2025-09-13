import 'package:get/get.dart';
import '../../data/repositories/properties_repository.dart';
import '../../data/models/property_model.dart';

class ListingDetailController extends GetxController {
  final PropertiesRepository _repository;
  ListingDetailController({required PropertiesRepository repository})
    : _repository = repository;

  final Rxn<Property> listing = Rxn<Property>();
  final RxBool isLoading = false.obs;
  String? _lastLoadedId;

  Future<void> load(String id) async {
    if (_lastLoadedId == id && listing.value != null) return;
    try {
      isLoading.value = true;
      listing.value = await _repository.getDetails(int.parse(id));
      _lastLoadedId = id;
    } finally {
      isLoading.value = false;
    }
  }
}
