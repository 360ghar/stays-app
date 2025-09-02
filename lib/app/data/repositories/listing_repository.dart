import '../providers/listing_provider.dart';
import '../services/storage_service.dart';
import '../models/listing_model.dart';

class ListingRepository {
  final ListingProvider _provider;
  final StorageService _storage;
  ListingRepository({required ListingProvider provider, required StorageService storage})
      : _provider = provider,
        _storage = storage;

  static const String _cacheKeyPrefix = 'listing_cache_';
  static const Duration _cacheExpiry = Duration(minutes: 5);

  Future<List<ListingModel>> getListings({Map<String, dynamic>? filters, int page = 1, int limit = 20}) async {
    final cacheKey = _generateCacheKey(filters ?? {}, page);
    final cached = await _storage.getCached(cacheKey);
    if (cached != null && !_isCacheExpired(cached['timestamp'] as String)) {
      final list = (cached['data'] as List).cast<Map<String, dynamic>>();
      return list.map(ListingModel.fromMap).toList();
    }
    final listings = await _provider.getListings(filters: filters, page: page, limit: limit);
    await _storage.cache(cacheKey, {
      'data': listings.map((e) => e.toMap()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    return listings;
  }

  Future<ListingModel> getListingById(String id) async {
    final cacheKey = '$_cacheKeyPrefix$id';
    final cached = await _storage.getCached(cacheKey);
    if (cached != null && !_isCacheExpired(cached['timestamp'] as String)) {
      return ListingModel.fromMap(cached['data'] as Map<String, dynamic>);
    }
    final listing = await _provider.getListingById(id);
    await _storage.cache(cacheKey, {
      'data': listing.toMap(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    return listing;
  }

  String _generateCacheKey(Map<String, dynamic> filters, int page) =>
      '$_cacheKeyPrefix${filters.hashCode}_$page';

  bool _isCacheExpired(String timestamp) {
    final cachedTime = DateTime.parse(timestamp);
    return DateTime.now().difference(cachedTime) > _cacheExpiry;
  }
}
