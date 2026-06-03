import 'package:stays_app/app/utils/helpers/json_helpers.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) =>
      NotificationModel(
        id: map['id']?.toString() ?? '',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        createdAt: JsonHelpers.getDateTime(map['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': JsonHelpers.toUtcIso8601(createdAt),
  };
}
