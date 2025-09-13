import 'package:get/get.dart';
import '../../data/repositories/properties_repository.dart';
import '../../data/models/property_model.dart';

class ListingController extends GetxController {
  final PropertiesRepository _repository;
  ListingController({required PropertiesRepository repository})
    : _repository = repository;

  final RxList<Property> listings = <Property>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    try {
      isLoading.value = true;
      final resp = await _repository.explore();
      listings.assignAll(resp.properties);
    } catch (_) {
      listings.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
