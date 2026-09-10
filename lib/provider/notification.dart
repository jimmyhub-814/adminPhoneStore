import 'package:admin/app_constants/auth_helper.dart';
import 'package:admin/app_constants/providers.dart';
import 'package:admin/models/admin_notification.dart';
import 'package:admin/models/notification.dart';
import 'package:admin/models/order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _notification = [];
  List<Map<String, dynamic>> get notification => [..._notification];

  void handleRemove(String id) async {
    for (int i = 0; i < notification.length; i++) {
      final noti = _notification.firstWhere(
        (item) => item[i].id == id,
      );
      _notification.remove(noti);
    }

    await Collections.notification(AuthHelper.adminId).doc(id).delete();

    notifyListeners();
  }

  Stream<List<AdminNotification>> getNotificationList() {
    try {
      return Collections.adminNotifications
          .orderBy(OrderInfo.orderDateField, descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return AdminNotification.fromMap(doc.data());
              } catch (e) {
                print('❌ lỗi parse: $e');
                return null;
              }
            })
            .whereType<AdminNotification>()
            .toList();
      });
    } catch (e) {
      print('Lỗi khi lấy danh sách thông báo: $e');
      return const Stream.empty();
    }
  }

  void readAllNotification() async {
    try {
      final snapshot = await Collections.notification(AuthHelper.adminId).get();

      if (snapshot.docs.isEmpty) {
        print("Không có tài liệu thông báo nào cho user: $AuthHelper.adminId");
        return;
      }

      print('Tổng số nhóm thông báo lấy được: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        await doc.reference
            .set({NotificationModel.readField: true}, SetOptions(merge: true));
      }

      print('Tất cả thông báo đã được đánh dấu là đã đọc');
    } catch (e) {
      print('Lỗi khi lấy danh sách thông báo: $e');
    }
  }
}
