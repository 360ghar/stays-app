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
    final query = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'page': page,
      'limit': limit,
      if (radiusKm > 0 && !(filters?.containsKey('radius') ?? false))
        'radius': radiusKm,
      ...?filters,
    };
    final res = await get('/api/v1/properties/', query: _stringify(query));
    return handleResponse(res, (json) {
      final rawList = (json['properties'] as List?) ??
          (json['data'] is Map<String, dynamic>
              ? (json['data'] as Map<String, dynamic>)['properties'] as List?
              : null);
      final props = rawList
              ?.map((e) => Property.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          <Property>[];
      final total = ((json['total'] ?? json['totalCount']) as num?)?.toInt() ??
          props.length;
      final totalPages =
          ((json['total_pages'] ?? json['totalPages']) as num?)?.toInt() ?? 1;
      final current =
          ((json['page'] ?? json['currentPage']) as num?)?.toInt() ?? page;
      final resolvedLimit = ((json['limit'] ?? json['pageSize'] ?? json['per_page'] ??
                  limit) as num?)
              ?.toInt() ??
          limit;
      final filtersApplied = json['filters_applied'] ?? json['filters'];
      return UnifiedPropertyResponse(
        properties: props,
        totalCount: total,
        currentPage: current,
        totalPages: totalPages,
        pageSize: resolvedLimit,
        filters: filtersApplied is Map
            ? Map<String, dynamic>.from(filtersApplied)
            : null,
      );
    });
  }

  Future<Property> getDetails(int id) async {
    final res = await get('/api/v1/properties/$id');
    return handleResponse(res, (json) {
      final data = json['data'] ?? json;
      return Property.fromJson(Map<String, dynamic>.from(data));
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
