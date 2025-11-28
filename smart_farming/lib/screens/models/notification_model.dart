// lib/screens/notification_model.dart

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'warning', 'info', 'success'
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(String id, Map<String, dynamic> json) {
    return NotificationModel(
      id: id,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'] ?? 'info',
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'isRead': isRead,
    };
  }
}