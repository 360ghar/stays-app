import 'package:stays_app/app/data/models/property_model.dart';

class Visit {
  final int id;
  final int propertyId;
  final DateTime scheduledDate;
  final String status;
  final String? specialRequirements;
  final Property? property;

  Visit({
    required this.id,
    required this.propertyId,
    required this.scheduledDate,
    required this.status,
    this.specialRequirements,
    this.property,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'] as int,
      propertyId: json['property_id'] as int,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      status: json['status'] as String? ?? 'pending',
      specialRequirements: json['special_requirements'] as String?,
      property: json['property'] is Map<String, dynamic>
          ? Property.fromJson(json['property'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'status': status,
      'special_requirements': specialRequirements,
      if (property != null) 'property': property!.toJson(),
    };
  }
}
