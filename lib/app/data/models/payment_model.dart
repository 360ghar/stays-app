import '../../utils/helpers/json_helpers.dart';

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.amount,
    this.currency = 'INR',
    this.status = 'pending',
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
    id: map['id']?.toString() ?? '',
    amount: JsonHelpers.getDouble(map['amount']) ?? 0,
    currency: JsonHelpers.getStringOrDefault(map['currency'], 'INR'),
    status: JsonHelpers.getStringOrDefault(map['status'], 'pending'),
  );
  final String id;
  final num amount;
  final String currency;
  final String status;

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'currency': currency,
    'status': status,
  };
}

/// A saved payment instrument returned by `/payments/methods`.
class PaymentMethodModel {
  const PaymentMethodModel({
    required this.id,
    required this.methodType,
    required this.createdAt,
    this.brand,
    this.last4,
    this.nickname,
    this.isDefault = false,
  });

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'];
    final parsedId = rawId is num
        ? rawId.toInt()
        : rawId is String
        ? int.tryParse(rawId) ?? 0
        : 0;
    return PaymentMethodModel(
      id: parsedId,
      methodType: JsonHelpers.getStringOrDefault(map['method_type'], 'card'),
      brand: JsonHelpers.getString(map['brand']),
      last4: JsonHelpers.getString(map['last4']),
      nickname: JsonHelpers.getString(map['nickname']),
      isDefault: map['is_default'] == true || map['is_default'] == 1,
      createdAt: _parseDateTime(map['created_at']),
    );
  }
  final int id;
  final String methodType;
  final String? brand;
  final String? last4;
  final String? nickname;
  final bool isDefault;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'method_type': methodType,
    'brand': brand,
    'last4': last4,
    'nickname': nickname,
    'is_default': isDefault,
    'created_at': createdAt.toIso8601String(),
  };

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is num) {
      final timestamp = value.toInt();
      return DateTime.fromMillisecondsSinceEpoch(
        timestamp > 1e12 ? timestamp : timestamp * 1000,
      );
    }
    return DateTime.now();
  }

  String get displayName {
    final parts = <String>[];
    if (brand != null && brand!.isNotEmpty) parts.add(brand!);
    if (last4 != null && last4!.isNotEmpty) parts.add('•••• $last4');
    if (parts.isEmpty) parts.add(methodType.toUpperCase());
    return parts.join(' ');
  }
}

/// Razorpay order creation response from `/payments/razorpay/order`.
class RazorpayOrderModel {
  const RazorpayOrderModel({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.bookingId,
    this.keyId,
    this.notes = const {},
  });

  factory RazorpayOrderModel.fromMap(Map<String, dynamic> map) {
    final rawNotes = map['notes'];
    final notes = <String, String>{};
    if (rawNotes is Map) {
      rawNotes.forEach((k, v) {
        if (v != null) notes[k.toString()] = v.toString();
      });
    }
    return RazorpayOrderModel(
      orderId: JsonHelpers.getStringOrDefault(map['order_id']),
      amount: JsonHelpers.getDouble(map['amount']) ?? 0.0,
      currency: JsonHelpers.getStringOrDefault(map['currency'], 'INR'),
      keyId: JsonHelpers.getString(map['key_id']),
      bookingId: JsonHelpers.getInt(map['booking_id']) ?? 0,
      notes: notes,
    );
  }
  final String orderId;
  final double amount;
  final String currency;
  final String? keyId;
  final int bookingId;
  final Map<String, String> notes;
}
