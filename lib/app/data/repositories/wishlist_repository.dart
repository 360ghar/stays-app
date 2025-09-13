import '../providers/swipes_provider.dart';
import '../models/property_model.dart';

class WishlistRepository {
  final SwipesProvider _provider;
  WishlistRepository({required SwipesProvider provider}) : _provider = provider;

  Future<void> add(int propertyId) =>
      _provider.swipe(propertyId: propertyId, isLiked: true);
  Future<void> remove(int propertyId) =>
      _provider.swipe(propertyId: propertyId, isLiked: false);

  Future<List<Property>> listFavorites({int page = 1, int limit = 20}) async {
    final json = await _provider.list(isLiked: true, page: page, limit: limit);
    final body =
        json['properties'] as List? ??
        (json['data']?['properties'] as List? ?? []);
    return body.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      // Normalize required numeric fields for Property model
      if (map['daily_rate'] == null && map['base_price'] != null) {
        final base = map['base_price'];
        if (base is num) map['daily_rate'] = base;
        if (base is String) {
          final parsed = double.tryParse(base);
          if (parsed != null) map['daily_rate'] = parsed;
        }
      }
      // Ensure required fields have sensible defaults
      map['purpose'] = map['purpose'] ?? 'short_stay';
      map['currency'] = map['currency'] ?? 'INR';
      map['title'] = map['title'] ?? map['name'] ?? 'Stay';
      map['country'] = map['country'] ?? '';
      map['city'] = map['city'] ?? '';
      return Property.fromJson(map);
    }).toList();
  }
}
