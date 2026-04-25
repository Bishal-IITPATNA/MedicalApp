class AppNotification {
  final int id;
  final int userId;
  final int? patientId;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final String createdAt;
  final int? relatedId;
  final String? relatedType;

  AppNotification({
    required this.id,
    required this.userId,
    this.patientId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    this.relatedId,
    this.relatedType,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      patientId: json['patient_id'],
      title: json['title'],
      message: json['message'],
      notificationType: json['notification_type'],
      isRead: json['is_read'],
      createdAt: json['created_at'],
      relatedId: json['related_id'],
      relatedType: json['related_type'],
    );
  }
}
