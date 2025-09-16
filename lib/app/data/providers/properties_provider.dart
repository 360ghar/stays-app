import 'base_provider.dart';
import '../models/property_model.dart';
import '../models/unified_property_response.dart';

class PropertiesProvider extends BaseProvider {
  Map<String, String> _stringify(Map<String, dynamic> m) {
    final out = <String, String>{};
    m.forEach((k, v) {
      if (v == null) return;
      if (v is List) {
        if (v.isNotEmpty) out[k] = v.join(',');
      } else {
        out[k] = v.toString();
      }
    });
    return out;
  }

  Future<UnifiedPropertyResponse> explore({
    required double lat,
    required double lng,
    int page = 1,
    int limit = 20,
    double radiusKm = 10,
    Map<String, dynamic>? filters,
  }) async {
    final query = {
      'lat': lat,
      'lng': lng,
      'page': page,
      'limit': limit,
      'radius': radiusKm.toInt(),
      ...?filters,
    };
    final res = await get('/api/v1/properties/', query: _stringify(query));
    return handleResponse(res, (json) {
      final props =
          (json['properties'] as List?)
              ?.map((e) => Property.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      final total = (json['total'] as num?)?.toInt() ?? props.length;
      final totalPages = (json['total_pages'] as num?)?.toInt() ?? 1;
      final current = (json['page'] as num?)?.toInt() ?? page;
      return UnifiedPropertyResponse(
        properties: props,
        totalCount: total,
        currentPage: current,
        totalPages: totalPages,
        filters: json['filters_applied'] as Map<String, dynamic>?,
      );
    });
  }

  Future<Property> getDetails(int id) async {
    final res = await get('/api/v1/properties/$id');
    return handleResponse(res, (json) {
      final data = json['data'] ?? json;
      return Property.fromJson(Map<String, dynamic>.from(data as Map));
    });
  }

  Future<List<Property>> recommendations({int limit = 10}) async {
    final res = await get(
      '/api/v1/properties/recommendations/',
      query: {'limit': '$limit'},
    );
    return handleResponse(res, (json) {
      final list = (json is List) ? json : (json['data'] as List? ?? []);
      return list
          .map((e) => Property.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
  }
}
