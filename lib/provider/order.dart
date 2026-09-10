import 'package:admin/app_constants/providers.dart';
import 'package:admin/models/order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderProvider extends ChangeNotifier {
  List<UserOrder> _orders = [];
  List<UserOrder> get orders => [..._orders];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    await getOrders();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateInfo(String orderId, String newInfo) async {
    final orderRef = Collections.orders.doc(orderId);

    final orderDoc = await orderRef.get();

    if (!orderDoc.exists) return;

    StatusHistory? status;
    final time = Timestamp.now();
    if (OrderStatus.values.any((e) => e.name == newInfo)) {
      status = StatusHistory(
        status: newInfo,
        time: time,
        updateBy: UpdateBy.admin.name,
      );
    }

    await orderRef.update({
      '${UserOrder.orderInfoField}.${OrderInfo.orderStatusField}': newInfo,
      '${UserOrder.orderInfoField}.${OrderInfo.lastStatusTimeField}': time,
      if (status != null)
        UserOrder.statusHistoryField: FieldValue.arrayUnion([status.toMap()]),
    });
  }

  Future<List<UserOrder>> getOrders() async {
    try {
      final data = await Collections.orders
          .orderBy(
              '${UserOrder.orderInfoField}.${OrderInfo.lastStatusTimeField}',
              descending: true)
          .get();

      _orders = data.docs
          .map(
            (item) => UserOrder.fromMap(
              item.data(),
            ),
          )
          .toList();

      return _orders;
    } catch (e) {
      print("Error loading user data: $e");
      return _orders;
    }
  }

  Stream<List<UserOrder>> streamOrders() {
    return Collections.orders
        .orderBy('${UserOrder.orderInfoField}.${OrderInfo.lastStatusTimeField}',
            descending: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs
            .map(
              (e) {
                try {
                  return UserOrder.fromMap(e.data());
                } catch (e) {
                  return null;
                }
              },
            )
            .whereType<UserOrder>()
            .toList();
      },
    );
  }

  Stream<List<UserOrder>> streamOrdersByStatus(String orStatus) {
    return Collections.orders
        .where('${UserOrder.orderInfoField}.${OrderInfo.orderStatusField}',
            isEqualTo: orStatus)
        .orderBy('${UserOrder.orderInfoField}.${OrderInfo.lastStatusTimeField}',
            descending: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs
            .map(
              (e) {
                try {
                  return UserOrder.fromMap(e.data());
                } catch (e) {
                  return null;
                }
              },
            )
            .whereType<UserOrder>()
            .toList();
      },
    );
  }

  Stream<List<UserOrder>> streamOrdersByStatuses(List<String> statuses) {
    return Collections.orders
        .where('${UserOrder.orderInfoField}.${OrderInfo.orderStatusField}',
            whereIn: statuses)
        .snapshots()
        .map((snap) => snap.docs
            .map(
              (doc) => UserOrder.fromMap(
                doc.data(),
              ),
            )
            .toList());
  }

  Future<List<UserOrder>> getAllOrderUser(String userId) async {
    final snapshot = await Collections.orders
        .where(
          "${UserOrder.userInfoField}.${OrderUserInfo.userIdField}",
          isEqualTo: userId,
        )
        .get();

    final List<UserOrder> orders = [];

    for (final doc in snapshot.docs) {
      try {
        orders.add(UserOrder.fromMap(doc.data()));
      } catch (e) {
        print("Loi parse doc ${doc.id}: $e");
      }
    }

    orders.sort((a, b) {
      final ta = a.orderInfo.lastStatusTime;
      final tb = b.orderInfo.lastStatusTime;

      return tb.compareTo(ta);
    });

    return orders;
  }

  Future<UserOrder?> getUserOrder(String orderId) async {
    try {
      final doc = await Collections.orders.doc(orderId).get();

      if (!doc.exists || doc.data() == null) return null;

      return UserOrder.fromMap(doc.data()!);
    } catch (e) {
      print("❌ getUserOrder error: $e");
      return null;
    }
  }
}
