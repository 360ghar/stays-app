import 'property_model.dart';

class UnifiedPropertyResponse {
  final List<Property> properties;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final Map<String, dynamic>? filters;

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;

  UnifiedPropertyResponse({
    required this.properties,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    this.filters,
  });

  factory UnifiedPropertyResponse.fromJson(Map<String, dynamic> json) {
    return UnifiedPropertyResponse(
      properties: (json['properties'] as List?)
              ?.map((e) => Property.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      totalCount: ((json['total'] ?? json['totalCount']) as num?)?.toInt() ?? 0,
      currentPage: ((json['page'] ?? json['currentPage']) as num?)?.toInt() ?? 1,
      totalPages: ((json['total_pages'] ?? json['totalPages']) as num?)?.toInt() ?? 1,
      pageSize: ((json['limit'] ?? json['pageSize'] ?? json['per_page']) as num?)?.toInt() ?? 20,
      filters: json['filters'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'properties': properties.map((e) => e.toJson()).toList(),
    'totalCount': totalCount,
    'currentPage': currentPage,
    'totalPages': totalPages,
    'pageSize': pageSize,
    'limit': pageSize,
    'filters': filters,
  };
}
