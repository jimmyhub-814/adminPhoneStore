import 'package:cloud_firestore/cloud_firestore.dart';

class Collections {
  static final products = FirebaseFirestore.instance.collection('products');

  static final admin = FirebaseFirestore.instance.collection('admin');

  static final adminNotifications = FirebaseFirestore.instance.collection('adminNotifications');

  static final categories = FirebaseFirestore.instance.collection('categories');

  static final users = FirebaseFirestore.instance.collection('users');

  static final orders = FirebaseFirestore.instance.collection('orders');

  static final statistics = FirebaseFirestore.instance.collection('statistics');
  
  static final conversations =
      FirebaseFirestore.instance.collection('conversations');

  static CollectionReference<Map<String, dynamic>> statisticsMonth(
          String statisticsId) =>
      Collections.statistics.doc(statisticsId).collection('statisticsMonth');

  static CollectionReference<Map<String, dynamic>> statisticsDay(
          String statisticsId, String statisticsMonthId) =>
      Collections.statistics
          .doc(statisticsId)
          .collection('statisticsMonth')
          .doc(statisticsMonthId)
          .collection('statisticsDay');

  static CollectionReference<Map<String, dynamic>> messages(String messageId) =>
      Collections.conversations.doc(messageId).collection('messages');

  static CollectionReference<Map<String, dynamic>> feedBacks(
          String productId) =>
      Collections.products.doc(productId).collection('feedBacks');

  static CollectionReference<Map<String, dynamic>> notification(
          String userId) =>
      Collections.users.doc(userId).collection('notifications');
}
