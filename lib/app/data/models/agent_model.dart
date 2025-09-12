import 'package:json_annotation/json_annotation.dart';

part 'agent_model.g.dart';

@JsonSerializable()
class AgentModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String? bio;
  final double? rating;
  final int? totalListings;
  final int? totalReviews;
  final DateTime? memberSince;
  final bool? isVerified;
  final String? agency;
  final String? licenseNumber;
  final List<String>? languages;
  final Map<String, dynamic>? metadata;

  AgentModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.bio,
    this.rating,
    this.totalListings,
    this.totalReviews,
    this.memberSince,
    this.isVerified,
    this.agency,
    this.licenseNumber,
    this.languages,
    this.metadata,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) => _$AgentModelFromJson(json);
  Map<String, dynamic> toJson() => _$AgentModelToJson(this);
}