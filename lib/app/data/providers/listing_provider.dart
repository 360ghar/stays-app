import 'base_provider.dart';
import '../models/listing_model.dart';

class ListingProvider extends BaseProvider {
  Future<List<ListingModel>> getListings({Map<String, dynamic>? filters, int page = 1, int limit = 20}) async {
    final response = await get('/listings', query: {...?filters, 'page': page, 'limit': limit});
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
