class Category {
   static const idField = 'id';
  static const categoryImageField = 'categoryImage';
  static const categoryNameField = 'categoryName';

  String id;
  String categoryImage;
  String categoryName;

  Category({
    required this.id,
    required this.categoryImage,
    required this.categoryName,
  });
  
  Map<String, dynamic> toMap() {
    return {
      idField: id,
      categoryImageField: categoryImage,
      categoryNameField: categoryName,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map[idField] as String,
      categoryImage: map[categoryImageField] as String,
      categoryName: map[categoryNameField] as String,
    );
  }
}
