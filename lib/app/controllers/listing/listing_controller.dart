import 'package:get/get.dart';
import '../../data/repositories/properties_repository.dart';
import '../../data/models/property_model.dart';
import '../../data/services/location_service.dart';

class ListingController extends GetxController {
  final PropertiesRepository _repository;
  final LocationService _locationService = Get.find<LocationService>();

  ListingController({required PropertiesRepository repository})
      : _repository = repository;

  final RxList<Property> listings = <Property>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;

  // Query snapshot (does not auto-change on refresh)
  double? _queryLat;
  double? _queryLng;
  double _radiusKm = 100.0; // default explore radius
  Map<String, dynamic>? _filters;

  @override
  void onInit() {
    super.onInit();
    _initQueryFromArgsOrService();
    fetch();
  }

  void _initQueryFromArgsOrService() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _queryLat = (args['lat'] as num?)?.toDouble() ?? _locationService.latitude;
      _queryLng = (args['lng'] as num?)?.toDouble() ?? _locationService.longitude;
      _radiusKm = (args['radius_km'] as num?)?.toDouble() ?? _radiusKm;
      final filters = args['filters'];
      if (filters is Map<String, dynamic>) _filters = filters;
    } else {
      _queryLat = _locationService.latitude;
      _queryLng = _locationService.longitude;
    }
  }

  Future<void> fetch() async {
    try {
      isLoading.value = true;
      final resp = await _repository.explore(
        lat: _queryLat,
        lng: _queryLng,
        radiusKm: _radiusKm,
        filters: _filters,
      );
      listings.assignAll(resp.properties);
    } catch (_) {
      listings.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // Public refresh entry used by RefreshIndicator. Does not change location.
  Future<void> refresh() async {
    try {
      isRefreshing.value = true;
      await fetch();
    } finally {
      isRefreshing.value = false;
    }
  }

  // Explicitly change the query location when user selects a new city.
  Future<void> setQueryLocation({
    required double lat,
    required double lng,
    double? radiusKm,
    Map<String, dynamic>? filters,
  }) async {
    _queryLat = lat;
    _queryLng = lng;
    if (radiusKm != null) _radiusKm = radiusKm;
    _filters = filters ?? _filters;
    await fetch();
  }
}
