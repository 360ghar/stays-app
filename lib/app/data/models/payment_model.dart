import 'package:json_annotation/json_annotation.dart';

part 'payment_model.g.dart';

@JsonSerializable()
class PaymentModel {
  final String id;
  final num amount;
  @JsonKey(defaultValue: 'USD')
  final String currency;
  @JsonKey(defaultValue: 'pending')
  final String status;

  const PaymentModel({
    required this.id,
    required this.amount,
    this.currency = 'USD',
    this.status = 'pending',
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentModelToJson(this);

  // Backwards compatibility
  factory PaymentModel.fromMap(Map<String, dynamic> map) =>
      PaymentModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}
