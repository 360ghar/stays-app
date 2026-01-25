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
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
  };
}
