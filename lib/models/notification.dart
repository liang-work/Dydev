class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String content;
  final String status;
  final bool isRead;
  final String createdAt;
  final int? software;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.status,
    required this.isRead,
    required this.createdAt,
    this.software,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as int,
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        isRead: json['is_read'] as bool? ?? false,
        createdAt: json['created_at'] as String? ?? '',
        software: json['software'] as int?,
      );
}
