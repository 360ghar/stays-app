import 'base_provider.dart';
import '../models/listing_model.dart';

class ListingProvider extends BaseProvider {
  Future<List<ListingModel>> getListings({Map<String, dynamic>? filters, int page = 1, int limit = 20}) async {
    // Stringify query params to avoid Uri builder type errors
    final Map<String, String> query = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (filters != null) {
      filters.forEach((key, value) {
        if (value == null) return;
        if (value is List) {
          if (value.isNotEmpty) query[key] = value.join(',');
        } else {
          query[key] = value.toString();
        }
      });
    }

    final response = await get('/listings', query: query);
    return handleResponse(response, (json) {
      final list = (json['listings'] as List? ?? []);
      return list.map((e) => ListingModel.fromMap(e as Map<String, dynamic>)).toList();
    });
  }

  Future<ListingModel> getListingById(String id) async {
    final response = await get('/listings/$id');
    return handleResponse(response, (json) => ListingModel.fromMap(json['listing'] as Map<String, dynamic>));
  }
}
