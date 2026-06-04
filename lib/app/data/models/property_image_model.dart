import 'package:json_annotation/json_annotation.dart';

part 'property_image_model.g.dart';

@JsonSerializable()
class PropertyImage {
  final int id;
  @JsonKey(name: 'property_id')
  final int propertyId;
  @JsonKey(name: 'image_url')
  final String imageUrl;
  final String? caption;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'is_main_image')
  final bool isMainImage;

  PropertyImage({
    required this.id,
    required this.propertyId,
    required this.imageUrl,
    this.caption,
    required this.displayOrder,
    this.isMainImage = false,
  });

  factory PropertyImage.fromJson(Map<String, dynamic> json) =>
      _$PropertyImageFromJson(json);
  Map<String, dynamic> toJson() => _$PropertyImageToJson(this);
}
