import 'package:admin/app_constants/storages.dart';
import 'package:flutter/material.dart';

class DataProvider extends ChangeNotifier {
  List<String> images = [];

  Future<void> fetchCarousel() async {
    final ref = Storages.carousels;
    final result = await ref.listAll();
    List<String> urls = [];

    for (var item in result.items) {
      final url = await item.getDownloadURL();
      urls.add(url);
    }
    images = urls;
    notifyListeners();
  }
}
