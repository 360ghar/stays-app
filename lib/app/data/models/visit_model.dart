import 'package:json_annotation/json_annotation.dart';

part 'visit_model.g.dart';

@JsonSerializable()
class VisitModel {
  final String id;
  final String userId;
  final String propertyId;
  final DateTime visitDate;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VisitModel({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.visitDate,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isUpcoming => DateTime.now().isBefore(visitDate) && status == 'scheduled';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  factory VisitModel.fromJson(Map<String, dynamic> json) => _$VisitModelFromJson(json);
  Map<String, dynamic> toJson() => _$VisitModelToJson(this);
}