import 'package:get/get.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/services/api_service.dart';

class PropertiesService extends GetxService {
  late final ApiService _apiService;

  Future<PropertiesService> init() async {
    _apiService = Get.find<ApiService>();
    return this;
  }

  // Fetch properties with optional filters
  Future<List<Property>> getProperties({
    String? propertyType,
    String? city,
    String? country,
    double? minPrice,
    double? maxPrice,
    int? page,
    int? limit,
    String? sortBy,
    String? searchQuery,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      // Add filters
      if (propertyType != null) queryParams['propertyType'] = propertyType;
      if (city != null) queryParams['city'] = city;
      if (country != null) queryParams['country'] = country;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (searchQuery != null) queryParams['search'] = searchQuery;

      final response = await _apiService.get(
        '/listings',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<dynamic> data = responseData is Map<String, dynamic> 
            ? responseData['properties'] ?? []
            : responseData is List ? responseData : [];
        
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load properties');
      }
    } catch (e) {
      print('Error fetching properties: $e');
      rethrow;
    }
  }

  // Get short stay properties
  Future<List<Property>> getShortStayProperties({
    String? city,
    String? country,
    double? minPrice,
    double? maxPrice,
    int? page,
    int? limit,
  }) async {
    return getProperties(
      propertyType: 'short_stay',
      city: city,
      country: country,
      minPrice: minPrice,
      maxPrice: maxPrice,
      page: page,
      limit: limit,
    );
  }

  // Get property by ID
  Future<Property> getPropertyById(String id) async {
    try {
      final response = await _apiService.get('/listings/$id');
      
      if (response.statusCode == 200) {
        return Property.fromJson(response.data);
      } else {
        throw Exception('Failed to load property details');
      }
    } catch (e) {
      print('Error fetching property by ID: $e');
      rethrow;
    }
  }

  // Search properties
  Future<List<Property>> searchProperties({
    required String query,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    List<String>? amenities,
    double? minRating,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'search': query,
      };
      
      if (propertyType != null) queryParams['propertyType'] = propertyType;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (amenities != null && amenities.isNotEmpty) {
        queryParams['amenities'] = amenities.join(',');
      }
      if (minRating != null) queryParams['minRating'] = minRating;

      final response = await _apiService.get(
        '/listings/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<dynamic> data = responseData is Map<String, dynamic> 
            ? responseData['properties'] ?? []
            : responseData is List ? responseData : [];
        
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Search failed');
      }
    } catch (e) {
      print('Error searching properties: $e');
      rethrow;
    }
  }

  // Get nearby properties based on coordinates
  Future<List<Property>> getNearbyProperties({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    String? propertyType,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'lat': latitude,
        'lng': longitude,
        'radius': radiusKm,
      };
      
      if (propertyType != null) queryParams['propertyType'] = propertyType;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get(
        '/listings/nearby',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<dynamic> data = responseData is Map<String, dynamic> 
            ? responseData['properties'] ?? []
            : responseData is List ? responseData : [];
        
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load nearby properties');
      }
    } catch (e) {
      print('Error fetching nearby properties: $e');
      rethrow;
    }
  }

  // Get recommended properties
  Future<List<Property>> getRecommendedProperties({
    String? userId,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (userId != null) queryParams['userId'] = userId;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get(
        '/listings/recommended',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<dynamic> data = responseData is Map<String, dynamic> 
            ? responseData['properties'] ?? []
            : responseData is List ? responseData : [];
        
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      print('Error fetching recommended properties: $e');
      rethrow;
    }
  }
}