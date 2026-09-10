import 'dart:io';
import 'package:admin/app_constants/providers.dart';
import 'package:admin/app_constants/storages.dart';
import 'package:admin/models/feedback.dart';
import 'package:admin/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _items = [];
  List<Product> get items => [..._items];
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isTrue = false;
  bool get isTrue => _isTrue;

  void toggleCheckBoxVisible() {
    _isTrue = !_isTrue;
    notifyListeners();
  }

  final Map<String, bool> _selectedItems = {};
  Map<String, bool> get selectedItems => {..._selectedItems};

  Future<void> fetchProductsList() async {
    _isLoading = true;
    notifyListeners();
    _items = await getAllProducts();

    notifyListeners();
  }

  List<Product> getResultOfSearch(String query) {
    if (query.isEmpty) return [];
    List<String> keywords = query.toLowerCase().split(" ");

    return _items.where((product) {
      String name = product.title.toLowerCase();
      return keywords.every((word) => name.contains(word));
    }).toList();
  }

  Future<Product?> getProduct(String id) async {
    _isLoading = true;

    try {
      final productRef = Collections.products.doc(id);
      final docSnapshot = await productRef.get();

      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data();
      if (data == null) return null;

      final product = Product.fromMap(data, data['id']);
      return product;
    } catch (e) {
      print('Lỗi khi lấy sản phẩm với id $id: $e');
      return null;
    } finally {
      _isLoading = false;
    }
  }

  Future<List<Product>> relatedItem(String id, String categoryId) async {
    try {
      final querySnapshot = await Collections.products
          .where(Product.categoryIdField, isEqualTo: categoryId)
          .get();

      List<Product> products = [];

      for (var doc in querySnapshot.docs) {
        final product = Product.fromMap(doc.data(), doc.id);

        if (product.id != id) {
          products.add(product);
        }
      }
      print('Related products found: ${products.length}');
      return products;
    } catch (e) {
      print('Lỗi khi lấy sản phẩm liên quan: $e');
      return [];
    }
  }

  Future<void> addItem(Product product) async {
    _isLoading = true;
    notifyListeners();

    final productRef = Collections.products.doc(product.id);
    await productRef.set(product.toMap());
    await Collections.feedBacks(product.id).doc('init').set({
      'init': true,
    });
    _isLoading = false;
    notifyListeners();
  }

  Future<List<FeedBack>> getFeedBack(String productId) async {
    List<FeedBack> feedbackList = [];

    try {
      final querySnapshot = await Collections.feedBacks(productId).get();

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

  Future<void> editItem(
      Product product,
      List<String> extraImagesAdd,
      List<String> extraImagesDelete,
      List<String> variantsImagesAdd,
      List<String> variantsImagesDelete) async {
    _isLoading = true;
    notifyListeners();
    if (variantsImagesDelete.isNotEmpty) {
      for (String i in variantsImagesDelete) {
        Storages.variant(i).delete();
      }
    }
    if (extraImagesDelete.isNotEmpty) {
      for (String i in extraImagesDelete) {
        Storages.product(i).delete();
      }
    }

    if (variantsImagesAdd.isNotEmpty) {
      await Future.wait(extraImagesAdd.asMap().entries.map((entry) async {
        final i = entry.key;
        final imagePath = entry.value;
        if (File(imagePath).existsSync()) {
          final id = const Uuid().v4();
          final ref = Storages.product(id);
          await ref.putFile(File(imagePath));
          final downloadUrl = await ref.getDownloadURL();
          product.extraImages[i] = downloadUrl;
        }
      }));
    }

    if (variantsImagesDelete.isNotEmpty) {
      await Future.wait(variantsImagesAdd.asMap().entries.map((entry) async {
        final i = entry.key;
        final imagePath = entry.value;
        if (File(imagePath).existsSync()) {
          final id = const Uuid().v4();
          final ref = Storages.variant(id);
          await ref.putFile(File(imagePath));
          final downloadUrl = await ref.getDownloadURL();
          product.listVariants[i].image = downloadUrl;
        }
      }));
    }

    final productRef = Collections.products.doc(product.id);
    await productRef.update(product.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<List<Product>> getAllProducts() async {
    _isLoading = true;

    final querySnapshot = await Collections.products.get();

    _items.clear();
    for (var doc in querySnapshot.docs) {
      try {
        final product = Product.fromMap(doc.data(), doc.id);

        // Loại bỏ sản phẩm lỗi
        if (product.listVariants.isEmpty ||
            product.mainImage.isEmpty ||
            product.title.isEmpty) {
          print('❌ Bỏ qua sản phẩm không hợp lệ: ${doc.id}');
          continue;
        }

        _items.add(product);
      } catch (e) {
        print('❌ Bỏ qua dữ liệu không hợp lệ: ${doc.id} - Lỗi: $e');
        continue;
      }
    }

    _isLoading = false;
    return _items;
  }

  Future<List<Product>> getProductsSameCategory(String categoryId) async {
    try {
      final querySnapshot = await Collections.products
          .where(Product.categoryIdField, isEqualTo: categoryId)
          .get();

      List<Product> list = [];

      for (var doc in querySnapshot.docs) {
        final product = Product.fromMap(doc.data(), doc.id);
        list.add(product);
      }

      return list;
    } catch (e) {
      print('Lỗi khi lấy sản phẩm theo danh mục: $e');
      return [];
    }
  }

  Future<void> increaseSalesVolume(List<Map<String, int>> productList) async {
    try {
      _isLoading = true;
      notifyListeners();

      final batch = FirebaseFirestore.instance.batch();
      Map<String, int> merged = {};
      for (var item in productList) {
        item.forEach((key, value) {
          merged[key] = (merged[key] ?? 0) + value;
        });
      }

      merged.forEach((id, quantity) {
        final docRef = Collections.products.doc(id);
        print("Đang cộng sản phẩm $id thêm $quantity");
        batch.update(docRef, {
          'salesVolume': FieldValue.increment(quantity),
        });
      });

      await batch.commit();
      print("Cộng xong ✅");
    } catch (e) {
      print("Lỗi khi cộng salesVolume: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetCheckBox() {
    _isTrue = false;
    clearSelectedItems();
    notifyListeners();
  }

  void clearSelectedItems() {
    _selectedItems.clear();
    notifyListeners();
  }

  Future<void> deleteProductAndRelatedData(String id) async {
    try {
      final doc = await Collections.products.doc(id).get();
      if (!doc.exists) return;

      final product =
          Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      final feedbacks = await Collections.feedBacks(id).get();
      for (var doc in feedbacks.docs) {
        await doc.reference.delete();
      }

      if (product.mainImage.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(product.mainImage).delete();
        } catch (_) {}
      }

      for (var url in product.extraImages) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (_) {}
      }

      for (var variant in product.listVariants) {
        try {
          if (variant.image != null && variant.image!.isNotEmpty)
            await FirebaseStorage.instance.refFromURL(variant.image!).delete();
        } catch (_) {}
      }

      await Collections.products.doc(id).delete();
    } catch (e) {
      print('❌ Delete failed: $e');
    }
  }

  Future<void> deleteSelectedProducts() async {
    _isLoading = true;
    notifyListeners();

    final selectedIds = _selectedItems.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    for (var id in selectedIds) {
      await deleteProductAndRelatedData(id);
    }
    _selectedItems.clear();
    _isTrue = false;
    _isLoading = false;
    notifyListeners();
  }

  void toggleSelection(String id) {
    _selectedItems[id] = !(_selectedItems[id] ?? false);
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    _isLoading = true;
    notifyListeners();
    Storages.products.delete();
    Storages.product(id).delete();
    _isLoading = false;
    notifyListeners();
  }
}
