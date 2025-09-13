import 'package:json_annotation/json_annotation.dart';
import 'package:stays_app/app/data/models/property_model.dart';

part 'wishlist_model.g.dart';

@JsonSerializable()
class WishlistItem {
  final String id;
  @JsonKey(
    name: 'propertyId',
    fromJson: _propertyIdFromJson,
    toJson: _propertyIdToJson,
  )
  final int propertyId;
  final String? userId;
  final String action; // 'like', 'unlike', 'pass'
  final DateTime? timestamp;
  final Property? property; // May include property details

  WishlistItem({
    required this.id,
    required this.propertyId,
    this.userId,
    required this.action,
    this.timestamp,
    this.property,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) =>
      _$WishlistItemFromJson(json);
  Map<String, dynamic> toJson() => _$WishlistItemToJson(this);

  bool get isLiked => action == 'like';
}

@JsonSerializable()
class SwipeHistory {
  final String id;
  @JsonKey(
    name: 'propertyId',
    fromJson: _propertyIdFromJson,
    toJson: _propertyIdToJson,
  )
  final int propertyId;
  final String? userId;
  final String action;
  final DateTime timestamp;
  final Property? property;

  SwipeHistory({
    required this.id,
    required this.propertyId,
    this.userId,
    required this.action,
    required this.timestamp,
    this.property,
  });

  factory SwipeHistory.fromJson(Map<String, dynamic> json) =>
      _$SwipeHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$SwipeHistoryToJson(this);
}

// Helper functions for propertyId conversion
int _propertyIdFromJson(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.parse(value);
  throw Exception('Invalid propertyId type: $value');
}

dynamic _propertyIdToJson(int value) => value;
