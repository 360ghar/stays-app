import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/property_model.dart';
import '../../data/repositories/properties_repository.dart';

class ListingDetailController extends GetxController {
  final PropertiesRepository _repository;
  ListingDetailController({required PropertiesRepository repository})
    : _repository = repository;

  final PageController galleryController = PageController();
  final Rxn<Property> listing = Rxn<Property>();
  final RxBool isLoading = false.obs;
  final RxInt currentImageIndex = 0.obs;
  String? _lastLoadedId;

  Future<void> load(String id) async {
    if (_lastLoadedId == id && listing.value != null) return;
    try {
      isLoading.value = true;
      final property = await _repository.getDetails(int.parse(id));
      setListing(property);
      _lastLoadedId = id;
    } finally {
      isLoading.value = false;
    }
  }

  void setListing(Property property) {
    listing.value = property;
    currentImageIndex.value = 0;
    if (galleryController.hasClients) {
      galleryController.jumpToPage(0);
    }
  }

  void updateImageIndex(int index) {
    currentImageIndex.value = index;
  }

  @override
  void onClose() {
    galleryController.dispose();
    super.onClose();
  }
}
