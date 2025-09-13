import 'package:get/get.dart';
import '../providers/properties_provider.dart';
import '../models/unified_property_response.dart';
import '../models/property_model.dart';
import '../services/location_service.dart';

class PropertiesRepository {
  final PropertiesProvider _provider;
  PropertiesRepository({required PropertiesProvider provider})
    : _provider = provider;

  Future<UnifiedPropertyResponse> explore({
    double? lat,
    double? lng,
    int page = 1,
    int limit = 20,
    double radiusKm = 10,
    Map<String, dynamic>? filters,
  }) async {
    double la = lat ?? 19.0760;
    double ln = lng ?? 72.8777;
    try {
      final loc = Get.find<LocationService>();
      if (loc.latitude != null && loc.longitude != null) {
        la = loc.latitude!;
        ln = loc.longitude!;
      }
    } catch (_) {}
    // Sanitize filters: remove non-lat/lng location filters, ensure default purpose
    final sanitized = <String, dynamic>{}..addAll(filters ?? {});
    const disallowed = {
      'city',
      'pincode',
      'locality',
      'sub_locality',
      'zip',
      'zipcode',
      'location',
      'country',
      'nearbyCity',
      'currentCity',
    };
    for (final k in disallowed) {
      sanitized.remove(k);
    }
    sanitized.putIfAbsent('purpose', () => 'short_stay');

    return _provider.explore(
      lat: la,
      lng: ln,
      page: page,
      limit: limit,
      radiusKm: radiusKm,
      filters: sanitized,
    );
  }

  Future<Property> getDetails(int id) => _provider.getDetails(id);

  Future<List<Property>> recommendations({int limit = 10}) =>
      _provider.recommendations(limit: limit);
}
