class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String topic;
  final String actionType; // 'open_city', 'open_attraction', 'open_url', 'open_trip'
  final String actionValue;
  final DateTime timestamp;
  final bool isRead;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.topic,
    required this.actionType,
    required this.actionValue,
    required this.timestamp,
    this.isRead = false,
  });

  AppNotificationModel copyWith({
    bool? isRead,
    String? title,
    String? body,
    String? imageUrl,
  }) {
    return AppNotificationModel(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      topic: topic,
      actionType: actionType,
      actionValue: actionValue,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map) {
    return AppNotificationModel(
      id: map['id'] as String? ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      topic: map['topic'] as String? ?? 'geral',
      actionType: map['actionType'] as String? ?? 'open_city',
      actionValue: map['actionValue'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      isRead: (map['isRead'] is int)
          ? (map['isRead'] as int) == 1
          : (map['isRead'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'topic': topic,
      'actionType': actionType,
      'actionValue': actionValue,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
    };
  }
}
