
class AppNotification {
  final String id;
  final String title;
  final String? body;
  final DateTime createdAt;
  final bool read;
  final String? category;

  AppNotification({
    required this.id,
    required this.title,
    this.body,
    required this.createdAt,
    this.read = false,
    this.category,
  });

  // Allows to create a new notification 
  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    category: category,
  );

  // These help to convert between JSON and Dart objects
  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    read: json['read'] as bool? ?? false,
    category: json['category'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
    'category': category,
  };
}
