import 'package:admin/app_constants/providers.dart';
import 'package:admin/models/feedback.dart'; 
import 'package:flutter/material.dart';

class FeedBackProvider extends ChangeNotifier {
  FeedBack? _feedBack;
  FeedBack? get feedBack => _feedBack;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> replyFeedBack(
    String productId,
    String reply,
    String feedbackId,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();
 
      final docRef = Collections.feedBacks(productId).doc(feedbackId);
 
      await docRef.update({
        FeedBack.adminReplyField: reply,
      });
    } catch (e) {
      print("❌ Error updating feedback: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<FeedBack>> getFeedBack(String productId) async {
    List<FeedBack> feedbackList = [];

    try {
      final querySnapshot = await Collections.feedBacks(productId)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        try {
          final feedback = FeedBack.fromMap(data);
          feedbackList.add(feedback);
        } catch (e) {
          debugPrint('❌ Lỗi khi parse feedback tại $productId - ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi lấy feedback cho sản phẩm $productId: $e');
    }

    return feedbackList;
  }

  Future<Map<String, FeedBack?>> getAllFeedBack(
      Map<String, Map<String, String>> itemMap) async {
    final futures = itemMap.entries.map((entry) async {
      final itemId = entry.key;
      final productId = entry.value['productId']!;
      final feedbackId = entry.value['feedbackId']!;

      try {
        final doc =
            await Collections.feedBacks(productId).doc(feedbackId).get();

        final fb = doc.exists ? FeedBack.fromMap(doc.data()!) : null;

        return MapEntry(itemId, fb);
      } catch (e) {
        debugPrint('❌ lỗi $productId - $feedbackId: $e');
        return MapEntry(itemId, null);
      }
    }).toList();

    final entries = await Future.wait(futures);

    entries.sort((a, b) {
      final t1 = a.value?.time;
      final t2 = b.value?.time;

      if (t1 == null || t2 == null) return 0;

      return t2.compareTo(t1); 
    });

    return Map.fromEntries(entries);
  }
}
