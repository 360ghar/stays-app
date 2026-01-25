// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_property_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnifiedPropertyResponse _$UnifiedPropertyResponseFromJson(
  Map<String, dynamic> json,
) => UnifiedPropertyResponse(
  properties: UnifiedPropertyResponse._propertiesFromJson(json['properties']),
  totalCount:
      (UnifiedPropertyResponse._readTotalCount(json, 'totalCount') as num)
          .toInt(),
  currentPage:
      (UnifiedPropertyResponse._readCurrentPage(json, 'currentPage') as num)
          .toInt(),
  totalPages:
      (UnifiedPropertyResponse._readTotalPages(json, 'totalPages') as num)
          .toInt(),
  pageSize: (UnifiedPropertyResponse._readPageSize(json, 'pageSize') as num)
      .toInt(),
  filters: json['filters'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$UnifiedPropertyResponseToJson(
  UnifiedPropertyResponse instance,
) => <String, dynamic>{
  'properties': instance.properties,
  'totalCount': instance.totalCount,
  'currentPage': instance.currentPage,
  'totalPages': instance.totalPages,
  'pageSize': instance.pageSize,
  'filters': instance.filters,
};
