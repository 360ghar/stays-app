import 'package:get/get.dart';
import 'package:stays_app/app/data/services/api_service.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class WishlistItem {
  final int id;
  final int propertyId;
  final dynamic property;
  
  WishlistItem({
    required this.id,
    required this.propertyId,
    this.property,
  });
  
  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'],
      propertyId: json['propertyId'] ?? json['property_id'],
      property: json['property'],
    );
  }
}

class WishlistService extends GetxService {
  // No longer 'late'! It's provided in the constructor.
  final ApiService _apiService;
  
  // Constructor to accept the dependency
  WishlistService(this._apiService);

  // The init method is now simpler
  Future<WishlistService> init() async {
    // Nothing to do here anymore, but we keep it for consistency with Get.putAsync
    return this;
  }

  // This should correspond to a dedicated wishlist endpoint.
  // Since one isn't listed, we'll assume a user profile endpoint returns favorites.
  // This part needs clarification from your backend team. For now, we'll assume
  // we fetch all listings and filter by a local 'isFavorite' flag updated by the user.
  // A proper implementation would have a GET /favorites endpoint.

  // CORRESPONDS TO: POST /properties/:id/like
  Future<bool> addToWishlist({required int propertyId}) async {
    try {
      // The endpoint in your docs is /properties/:id/like
      // The existing backend seems to be using /properties/:id/like
      final response = await _apiService.post('/properties/$propertyId/like', {});
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      AppLogger.error('Error adding to wishlist', e);
      return false;
    }
  }

  // CORRESPONDS TO: DELETE /properties/:id/like (assuming unlike)
  Future<bool> removeFromWishlist({required int propertyId}) async {
    try {
      // Assuming 'unlike' is the correct corresponding action
      final response = await _apiService.post('/properties/$propertyId/unlike', {});
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      AppLogger.error('Error removing from wishlist', e);
      return false;
    }
  }

  // Get user's wishlist items
  Future<List<WishlistItem>> getUserWishlist() async {
    try {
      final response = await _apiService.get('/user/wishlist');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.body?['data'] ?? [];
        return data.map((json) => WishlistItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.error('Error getting user wishlist', e);
      return [];
    }
  }

  // Clear all wishlist items
  Future<bool> clearWishlist() async {
    try {
      final response = await _apiService.delete('/user/wishlist');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      AppLogger.error('Error clearing wishlist', e);
      return false;
    }
  }
}