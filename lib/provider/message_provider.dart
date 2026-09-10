import 'package:admin/app_constants/providers.dart';
import 'package:admin/models/message.dart';
import 'package:flutter/material.dart';

class MessageProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<List<Message>?> getMessageBefore(String userId, int before) async {
    _isLoading = true;
    List<Message> messageList = [];

    final querySnapshot = await Collections.messages(userId)
        .where(Message.timeField, isLessThan: before)
        .orderBy(Message.timeField, descending: true)
        .limit(5)
        .get();

    for (var doc in querySnapshot.docs) {
      try {
        final data = doc.data();
        final message = Message.fromMap(data);
        messageList.add(message);
      } catch (e) {
        print('❌ Bỏ qua dữ liệu không hợp lệ: $doc - Lỗi: $e');
        continue;
      }
    }

    _isLoading = false;
    return messageList;
  }

  Future<List<Message>?> getMessage(String userId) async {
    _isLoading = true;
    List<Message> messageList = [];

    final querySnapshot = await Collections.messages(userId)
        .orderBy(Message.timeField, descending: true)
        .limit(20)
        .get();

    for (var doc in querySnapshot.docs) {
      try {
        final data = doc.data();
        final message = Message.fromMap(data);
        messageList.add(message);
      } catch (e) {
        print('❌ Bỏ qua dữ liệu không hợp lệ: $doc - Lỗi: $e');
        continue;
      }
    }
    _isLoading = false;
    return messageList;
  }

  Stream<Message> streamMessage(String userId, int after) {
    return Collections.messages(userId)
        .where(Message.timeField, isGreaterThan: after)
        .snapshots()
        .expand((snapshot) => snapshot.docs)
        .map((doc) {
          try {
            return Message.fromMap(doc.data());
          } catch (e) {
            debugPrint('❌ Skip invalid message ${doc.id}: $e');
            return null;
          }
        })
        .where((m) => m != null)
        .cast<Message>();
  }
}
