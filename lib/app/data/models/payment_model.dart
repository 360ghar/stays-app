class PaymentModel {
  final String id;
  final num amount;
  final String currency;
  final String status;

  const PaymentModel({
    required this.id,
    required this.amount,
    this.currency = 'USD',
    this.status = 'pending',
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
    id: map['id']?.toString() ?? '',
    amount: map['amount'] as num? ?? 0,
    currency: map['currency'] as String? ?? 'USD',
    status: map['status'] as String? ?? 'pending',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'currency': currency,
    'status': status,
  };
}
