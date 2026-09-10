import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  static const idField = 'id';
  static const notificationListField = 'notificationList';
  static const readField = 'read';

  final String id;
  final List<NotificationList> notificationList;
  final bool read;

  NotificationModel({
    required this.id,
    required this.notificationList,
    required this.read,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map[idField] ?? '',
      notificationList: (map[notificationListField] as List<dynamic>? ?? [])
          .map((e) => NotificationList.fromMap(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      read: map[readField] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      notificationListField: notificationList.map((e) => e.toMap()).toList(),
      readField: read,
    };
  }
}

class NotificationList {
  static const idField = 'id';
  static const titleField = 'title';
  static const timestampField = 'timestamp';
  static const bodyField = 'body';

  final String id;
  final String title;
  final String body;
  final Timestamp timestamp;

  NotificationList({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  factory NotificationList.fromMap(Map<String, dynamic> map) {
    return NotificationList(
      id: map[idField] ?? '',
      title: map[titleField] ?? '',
      body: map[bodyField] ?? '',
      timestamp: map[timestampField] is Timestamp
          ? map[timestampField]
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      titleField: title,
      bodyField: body,
      timestampField: timestamp,
    };
  }
}
