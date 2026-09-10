import 'package:admin/app_constants/providers.dart';
import 'package:admin/models/conversation.dart';
import 'package:flutter/material.dart';

class ConversationProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<Conversation?>> streamConversation() {
    return Collections.conversations
        .orderBy(Conversation.lastMessageTimeField, descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return Conversation.fromMap(doc.data());
            } catch (e) {
              print('$e');
              return null;
            }
          })
          .whereType<Conversation>()
          .toList();
    });
  }

  Future<Conversation?> getConversation(String id) async {
    _isLoading = true;
    try {
      final doc = Collections.conversations.doc(id);
      final ref = await doc.get();
      if (!ref.exists) {
        return null;
      }

      final data = ref.data();
      if (data == null) return null;
      final conversation = Conversation.fromMap(data);
      return conversation;
    } finally {
      _isLoading = true;
    }
  }

  Future<List<Conversation>?> getAllConversation() async {
    List<Conversation> conList = [];

    final querySnapshot = await Collections.conversations
        .orderBy(Conversation.lastMessageTimeField, descending: true)
        .limit(10)
        .get();

    for (var doc in querySnapshot.docs) {
      try {
        final data = doc.data();
        final conversation = Conversation.fromMap(data);
        conList.add(conversation);
      } catch (e) {
        print('❌ Bỏ qua dữ liệu không hợp lệ: $doc - Lỗi: $e');
        continue;
      }
    }

    return conList;
  }
}
