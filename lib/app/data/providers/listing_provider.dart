import 'base_provider.dart';
import '../models/listing_model.dart';

// NOTE: This provider targets the `/listings` endpoint, which appears to be
// dead code. There are no callers of `ListingProvider` or `ListingRepository`
// anywhere in `lib/` (no Get registration, no instantiation). The cursor
// pagination migration is therefore intentionally skipped here. If this
// endpoint is reactivated, switch `page` -> `cursor` and parse `items` /
// `next_cursor` / `has_more` from the response envelope.
class ListingProvider extends BaseProvider {
  Future<List<ListingModel>> getListings({
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await get(
      '/listings',
      query: {...?filters, 'page': page, 'limit': limit},
    );
    return handleResponse(response, (json) {
      final list = (json['listings'] as List? ?? []);
      return list
          .map((e) => ListingModel.fromMap(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<ListingModel> getListingById(String id) async {
    final response = await get('/listings/$id');
    return handleResponse(
      response,
      (json) => ListingModel.fromMap(json['listing'] as Map<String, dynamic>),
    );
  }
}
