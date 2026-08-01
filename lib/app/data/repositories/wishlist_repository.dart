import '../providers/swipes_provider.dart';
import '../models/unified_property_response.dart';

class WishlistRepository {
  WishlistRepository({required SwipesProvider provider}) : _provider = provider;
  final SwipesProvider _provider;

  Future<void> add(int propertyId) =>
      _provider.swipe(propertyId: propertyId, isLiked: true);
  Future<void> remove(int propertyId) =>
      _provider.swipe(propertyId: propertyId, isLiked: false);

  /// Remove many liked properties in one backend call (audit UX #9).
  Future<void> clearAll(List<int> propertyIds) =>
      _provider.batchRemove(propertyIds);

  Future<UnifiedPropertyResponse> listFavorites({
    String? cursor,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) {
    // Parsing and item normalization live in SwipesProvider.list; this layer
    // only pins the wishlist filter (isLiked: true).
    return _provider.list(
      isLiked: true,
      cursor: cursor,
      limit: limit,
      filters: filters,
    );
  }
}
