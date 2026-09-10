import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotification {
  static const orderIdField = 'orderId';
  static const orderDateField = 'orderDate';
  static const statusField = 'status';

  String orderId;
  Timestamp orderDate;
  String status;

  AdminNotification({
    required this.orderId,
    required this.orderDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      orderIdField: orderId,
      orderDateField: orderDate,
      statusField: status,
    };
  }

  factory AdminNotification.fromMap(Map<String, dynamic> map) {
    return AdminNotification(
      status: map[statusField]?.toString() ?? '',
      orderDate: map[orderDateField] is Timestamp
          ? map[orderDateField]
          : Timestamp.now(),
      orderId: map[orderIdField]?.toString() ?? '',
    );
  }
}
