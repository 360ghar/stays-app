import 'base_provider.dart';
import '../models/listing_model.dart';

class ListingProvider extends BaseProvider {
  Future<List<ListingModel>> getListings({Map<String, dynamic>? filters, int page = 1, int limit = 20}) async {
    // Normalize query params to strings and join list values
    final Map<String, String> query = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (filters != null) {
      filters.forEach((key, value) {
        if (value == null) return;
        if (value is Iterable) {
          final items = value.where((e) => e != null).map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
          if (items.isNotEmpty) query[key] = items.join(',');
        } else {
          final s = value.toString();
          if (s.trim().isNotEmpty) query[key] = s;
        }
      });
    }
    final response = await get('/listings', query: query);
    return handleResponse(response, (json) {
      // Support multiple response shapes: {results: [...]}, {listings: [...]}, or {data: [...]}
      final dynamic raw = json['results'] ?? json['listings'] ?? json['data'];
      final List list = raw is List ? raw : const <dynamic>[];
      return list.map((e) => ListingModel.fromMap(e as Map<String, dynamic>)).toList();
    });
  }

  Future<ListingModel> getListingById(String id) async {
    final response = await get('/listings/$id');
    return handleResponse(response, (json) => ListingModel.fromMap(json['listing'] as Map<String, dynamic>));
  }
}
