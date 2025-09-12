import 'property_model.dart';

class UnifiedPropertyResponse {
  final List<Property> properties;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final Map<String, dynamic>? filters;

  UnifiedPropertyResponse({
    required this.properties,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    this.filters,
  });

  factory UnifiedPropertyResponse.fromJson(Map<String, dynamic> json) {
    return UnifiedPropertyResponse(
      properties: (json['properties'] as List?)
          ?.map((e) => Property.fromJson(e))
          .toList() ?? [],
      totalCount: json['totalCount'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      filters: json['filters'],
    );
  }

  Map<String, dynamic> toJson() => {
    'properties': properties.map((e) => e.toJson()).toList(),
    'totalCount': totalCount,
    'currentPage': currentPage,
    'totalPages': totalPages,
    'filters': filters,
  };
}