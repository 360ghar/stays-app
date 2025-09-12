class TripModel {
  final String id;
  final String propertyName;
  final DateTime checkIn;
  final DateTime checkOut;
  final String status;
  final String? propertyImage;
  final double? totalCost;
  final String? hostName;

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
        propertyName: map['propertyName'] as String? ?? '',
        checkIn: DateTime.parse(map['checkIn'] as String),
        checkOut: DateTime.parse(map['checkOut'] as String),
        status: map['status'] as String? ?? 'pending',
        propertyImage: map['propertyImage'] as String?,
        totalCost: (map['totalCost'] as num?)?.toDouble(),
        hostName: map['hostName'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'propertyName': propertyName,
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
        'status': status,
        'propertyImage': propertyImage,
        'totalCost': totalCost,
        'hostName': hostName,
      };
}