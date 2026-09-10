import 'package:admin/app_constants/providers.dart';
import 'package:admin/app_constants/storages.dart';
import 'package:admin/models/category.dart';
import 'package:admin/models/product.dart'; 
import 'package:flutter/material.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  List<Category> get categories => [..._categories];
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

  Future<void> fetchCategoriesList() async {
    _isLoading = true;
    notifyListeners();
    _categories = await getCategories();

    notifyListeners();
  }

  void toggleSelection(String id) {
    _selectedItems[id] = !(_selectedItems[id] ?? false);
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    _isLoading = true;
    notifyListeners();

    final categoriesRef = Collections.categories.doc(category.id);
    await categoriesRef.set(category.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> editItem(Category category) async {
    _isLoading = true;
    notifyListeners();
    final productRef = Collections.categories.doc(category.id);
    await productRef.update(category.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteSelectedCategories() async {
    _isLoading = true;
    notifyListeners();

    final selectedIds = _selectedItems.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    for (var id in selectedIds) {
      await deleteCategoryWithProducts(id);  
    }

    _selectedItems.clear();  
    _isTrue = false;  
    _isLoading = false;
    notifyListeners();
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
    final feedbacks = await Collections.feedBacks(id).get();

    for (var doc in feedbacks.docs) {
      await doc.reference.delete();
    }

    await Collections.products.doc(id).delete();

    await Storages.product(id).delete();
  }

  Future<void> deleteCategoryWithProducts(String categoryId) async {
    _isLoading = true;
    notifyListeners();

    final querySnapshot = await Collections.products
        .where(Product.categoryIdField, isEqualTo: categoryId)
        .get();

    for (var doc in querySnapshot.docs) {
      await deleteProductAndRelatedData(doc.id);
    }

    Storages.category(categoryId).delete();
    await Collections.categories.doc(categoryId).delete();
    _selectedItems.clear(); 
    _isTrue = false; 
    _isLoading = false;
    if (hasListeners) notifyListeners();
  }

  Future<List<Category>> getCategories() async {
    final querySnapshot = await Collections.categories.get();

    _categories.clear();
    for (var doc in querySnapshot.docs) {
      try {
        final category = Category.fromMap(doc.data());
        _categories.add(category);
      } catch (e) {
        print('❌ Bỏ qua dữ liệu không hợp lệ: ${doc.id} - Lỗi: $e');
        continue;
      }
    }

    return _categories;
  }
}
