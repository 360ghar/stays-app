import 'package:stays_app/app/utils/helpers/json_helpers.dart';

class TripModel {
  TripModel({
    required this.id,
    required this.propertyName,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    this.propertyImage,
    this.totalCost,
    this.hostName,
  });

  factory TripModel.fromMap(Map<String, dynamic> map) => TripModel(
    id: map['id']?.toString() ?? '',
    propertyName: JsonHelpers.getStringOrDefault(map['propertyName']),
    checkIn: JsonHelpers.getDateTime(map['checkIn']) ?? DateTime.now(),
    checkOut:
        JsonHelpers.getDateTime(map['checkOut']) ??
        (JsonHelpers.getDateTime(map['checkIn']) ?? DateTime.now()),
    status: JsonHelpers.getStringOrDefault(map['status'], 'pending'),
    propertyImage: JsonHelpers.getString(map['propertyImage']),
    totalCost: JsonHelpers.getDouble(map['totalCost']),
    hostName: JsonHelpers.getString(map['hostName']),
  );
  final String id;
  final String propertyName;
  final DateTime checkIn;
  final DateTime checkOut;
  final String status;
  final String? propertyImage;
  final double? totalCost;
  final String? hostName;

  Map<String, dynamic> toMap() => {
    'id': id,
    'propertyName': propertyName,
    'checkIn': JsonHelpers.toDateOnly(checkIn),
    'checkOut': JsonHelpers.toDateOnly(checkOut),
    'status': status,
    'propertyImage': propertyImage,
    'totalCost': totalCost,
    'hostName': hostName,
  };
}
