import 'base_provider.dart';
import '../../utils/extensions/http_extensions.dart';
import '../models/property_model.dart';
import '../models/unified_property_response.dart';

/// A property detail plus whether the response must not be cached.
typedef PropertyDetailResult = ({Property property, bool noStore});

class PropertiesProvider extends BaseProvider {
  PropertiesProvider({super.dio});

  /// `GET /api/v1/properties`. [radiusKm] is a whole number of 1 to 100: the
  /// backend reads `radius` as an integer. A list filter in [filters] is sent
  /// as repeated keys.
  Future<UnifiedPropertyResponse> explore({
    required double lat,
    required double lng,
    String? cursor,
    int limit = 20,
    int radiusKm = 10,
    Map<String, dynamic>? filters,
  }) async {
    final effectiveCursor = (cursor != null && cursor.trim().isEmpty)
        ? null
        : cursor;
    final query = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'cursor': ?effectiveCursor,
      'limit': limit,
      if (radiusKm > 0 && !(filters?.containsKey('radius') ?? false))
        'radius': radiusKm.clamp(1, 100),
      ...?filters,
    };
    final res = await get('/api/v1/properties', query: query.asQueryParams());
    return handleResponse(
      res,
      (json) => UnifiedPropertyResponse.fromJson(json, noStore: res.noStore),
    );
  }

  Future<PropertyDetailResult> getDetails(int id) async {
    final res = await get('/api/v1/properties/$id');
    return handleResponse(res, (json) {
      final map = Map<String, dynamic>.from(json as Map);
      return (property: Property.fromJson(map), noStore: res.noStore);
    });
  }

  /// `GET /api/v1/properties/recommendations`, a `CursorPage`. This reads the
  /// first page only.
  Future<UnifiedPropertyResponse> recommendations({int limit = 10}) async {
    final res = await get(
      '/api/v1/properties/recommendations',
      query: {'limit': '$limit'},
    );
    return handleResponse(
      res,
      (json) => UnifiedPropertyResponse.fromJson(json, noStore: res.noStore),
    );
  }
}
