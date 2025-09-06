import 'package:get/get.dart';
import 'package:stays_app/app/data/models/wishlist_model.dart';
import 'package:stays_app/app/data/services/api_service.dart';

class WishlistService extends GetxService {
  late final ApiService _apiService;

  Future<WishlistService> init() async {
    _apiService = Get.find<ApiService>();
    return this;
  }

  // Get user's wishlist (liked properties)
  Future<List<WishlistItem>> getUserWishlist({
    String? userId,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (userId != null) queryParams['userId'] = userId;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get(
        '/swipes',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : response.data['data'] ?? [];
        
        // Filter only liked items
        final likedItems = data.where((item) => 
          item['action'] == 'like' || item['liked'] == true
        ).toList();
        
        return likedItems.map((json) => WishlistItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load wishlist');
      }
    } catch (e) {
      print('Error fetching wishlist: $e');
      rethrow;
    }
  }

  // Add property to wishlist (like/swipe right)
  Future<bool> addToWishlist({
    required int propertyId,
    String? userId,
  }) async {
    try {
      final response = await _apiService.post(
        '/swipes',
        data: {
          'propertyId': propertyId,
          'userId': userId,
          'action': 'like',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding to wishlist: $e');
      return false;
    }
  }

  // Remove from wishlist (unlike)
  Future<bool> removeFromWishlist({
    required int propertyId,
    String? userId,
  }) async {
    try {
      final response = await _apiService.delete(
        '/swipes/$propertyId',
        queryParameters: userId != null ? {'userId': userId} : null,
      );

      if (response.statusCode == 404) {
        // If delete endpoint doesn't exist, try updating the swipe
        return await updateSwipe(
          propertyId: propertyId,
          userId: userId,
          action: 'unlike',
        );
      }

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error removing from wishlist: $e');
      return false;
    }
  }

  // Update swipe action
  Future<bool> updateSwipe({
    required int propertyId,
    String? userId,
    required String action, // 'like', 'unlike', 'pass'
  }) async {
    try {
      final response = await _apiService.put(
        '/swipes/$propertyId',
        data: {
          'userId': userId,
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating swipe: $e');
      return false;
    }
  }

  // Check if property is in wishlist
  Future<bool> isInWishlist({
    required int propertyId,
    String? userId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'propertyId': propertyId,
      };
      
      if (userId != null) queryParams['userId'] = userId;

      final response = await _apiService.get(
        '/swipes/check',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data['liked'] == true || 
               response.data['action'] == 'like';
      }
      
      return false;
    } catch (e) {
      print('Error checking wishlist status: $e');
      return false;
    }
  }

  // Get swipe history
  Future<List<SwipeHistory>> getSwipeHistory({
    String? userId,
    String? action, // Filter by action: 'like', 'pass', etc.
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (userId != null) queryParams['userId'] = userId;
      if (action != null) queryParams['action'] = action;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get(
        '/swipes/history',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : response.data['data'] ?? [];
        
        return data.map((json) => SwipeHistory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load swipe history');
      }
    } catch (e) {
      print('Error fetching swipe history: $e');
      rethrow;
    }
  }

  // Clear entire wishlist
  Future<bool> clearWishlist({String? userId}) async {
    try {
      final response = await _apiService.delete(
        '/swipes/clear',
        queryParameters: userId != null ? {'userId': userId} : null,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error clearing wishlist: $e');
      return false;
    }
  }
}