// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_image_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyImage _$PropertyImageFromJson(Map<String, dynamic> json) =>
    PropertyImage(
      id: (json['id'] as num).toInt(),
      propertyId: (json['property_id'] as num).toInt(),
      imageUrl: json['image_url'] as String,
      caption: json['caption'] as String?,
      displayOrder: (json['display_order'] as num).toInt(),
      isMainImage: json['is_main_image'] as bool? ?? false,
    );

Map<String, dynamic> _$PropertyImageToJson(PropertyImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'property_id': instance.propertyId,
      'image_url': instance.imageUrl,
      'caption': instance.caption,
      'display_order': instance.displayOrder,
      'is_main_image': instance.isMainImage,
    };
