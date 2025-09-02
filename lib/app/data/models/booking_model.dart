class BookingModel {
  final String id;
  final String listingId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final num totalPrice;

  const BookingModel({
    required this.id,
    required this.listingId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.totalPrice,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) => BookingModel(
        id: map['id']?.toString() ?? '',
        listingId: map['listingId']?.toString() ?? '',
        checkIn: DateTime.parse(map['checkIn'] as String),
        checkOut: DateTime.parse(map['checkOut'] as String),
        guests: map['guests'] as int? ?? 1,
        totalPrice: map['totalPrice'] as num? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'listingId': listingId,
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
        'guests': guests,
        'totalPrice': totalPrice,
      };
}

