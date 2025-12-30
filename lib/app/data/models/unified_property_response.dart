import 'package:json_annotation/json_annotation.dart';
import 'property_model.dart';

part 'unified_property_response.g.dart';

@JsonSerializable(createToJson: true)
class UnifiedPropertyResponse {
  @JsonKey(fromJson: _propertiesFromJson)
  final List<Property> properties;
  @JsonKey(readValue: _readTotalCount)
  final int totalCount;
  @JsonKey(readValue: _readCurrentPage)
  final int currentPage;
  @JsonKey(readValue: _readTotalPages)
  final int totalPages;
  @JsonKey(readValue: _readPageSize)
  final int pageSize;
  final Map<String, dynamic>? filters;

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;

  const UnifiedPropertyResponse({
    required this.properties,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    this.filters,
  });

  factory UnifiedPropertyResponse.fromJson(Map<String, dynamic> json) =>
      _$UnifiedPropertyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedPropertyResponseToJson(this);

  static List<Property> _propertiesFromJson(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Property.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Object? _readTotalCount(Map<dynamic, dynamic> json, String key) =>
      json['total'] ?? json['totalCount'] ?? 0;

  static Object? _readCurrentPage(Map<dynamic, dynamic> json, String key) =>
      json['page'] ?? json['currentPage'] ?? 1;

  static Object? _readTotalPages(Map<dynamic, dynamic> json, String key) =>
      json['total_pages'] ?? json['totalPages'] ?? 1;

  static Object? _readPageSize(Map<dynamic, dynamic> json, String key) =>
      json['limit'] ?? json['pageSize'] ?? json['per_page'] ?? 20;
}
