import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/data/services/places_service.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class LocationSearchController extends GetxController {
  late final PlacesService _placesService;
  late final LocationService _locationService;

  final RxString query = ''.obs;
  final RxBool isLoading = false.obs;
  final RxList<PlacePrediction> predictions = <PlacePrediction>[].obs;
  final TextEditingController textController = TextEditingController();
  Worker? _searchWorker;

  @override
  void onInit() {
    super.onInit();
    _placesService = Get.find<PlacesService>();
    _locationService = Get.find<LocationService>();
    _searchWorker = debounce<String>(
      query,
      (q) => _search(q),
      time: const Duration(milliseconds: 250),
    );
  }

  @override
  void onClose() {
    textController.dispose();
    _searchWorker?.dispose();
    super.onClose();
  }

  void onQueryChanged(String value) {
    query.value = value;
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      predictions.clear();
      return;
    }
    isLoading.value = true;
    try {
      final lat = _locationService.latitude;
      final lng = _locationService.longitude;
      final results = await _placesService.autocomplete(q, lat: lat, lng: lng);
      predictions.assignAll(results);
    } catch (e) {
      AppLogger.error('Location search failed', e);
      predictions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectPrediction(PlacePrediction prediction) async {
    try {
      isLoading.value = true;
      final details = await _placesService.details(prediction.placeId);
      if (details == null) return;
      _locationService.setSelectedLocation(
        lat: details.lat,
        lng: details.lng,
        locationName: details.name,
      );
      Get.back(
        result: {'lat': details.lat, 'lng': details.lng, 'name': details.name},
      );
    } finally {
      isLoading.value = false;
    }
  }
}
