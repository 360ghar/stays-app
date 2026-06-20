class PaymentModel {
  final String id;
  final num amount;
  final String currency;
  final String status;

  const PaymentModel({
    required this.id,
    required this.amount,
    this.currency = 'INR',
    this.status = 'pending',
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
    id: map['id']?.toString() ?? '',
    amount: map['amount'] as num? ?? 0,
    currency: map['currency'] as String? ?? 'INR',
    status: map['status'] as String? ?? 'pending',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'currency': currency,
    'status': status,
  };
}

/// A saved payment instrument returned by `/payments/methods`.
class PaymentMethodModel {
  final int id;
  final String methodType;
  final String? brand;
  final String? last4;
  final String? nickname;
  final bool isDefault;
  final DateTime createdAt;

  const PaymentMethodModel({
    required this.id,
    required this.methodType,
    this.brand,
    this.last4,
    this.nickname,
    this.isDefault = false,
    required this.createdAt,
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
      methodType: map['method_type'] as String? ?? 'card',
      brand: map['brand'] as String?,
      last4: map['last4'] as String?,
      nickname: map['nickname'] as String?,
      isDefault: map['is_default'] == true || map['is_default'] == 1,
      createdAt: _parseDateTime(map['created_at']),
    );
  }

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
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value > 1e12 ? value : value * 1000,
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
  final String orderId;
  final double amount;
  final String currency;
  final String? keyId;
  final int bookingId;
  final Map<String, String> notes;

  const RazorpayOrderModel({
    required this.orderId,
    required this.amount,
    required this.currency,
    this.keyId,
    required this.bookingId,
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
      orderId: map['order_id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'INR',
      keyId: map['key_id'] as String?,
      bookingId: (map['booking_id'] as num?)?.toInt() ?? 0,
      notes: notes,
    );
  }
}
