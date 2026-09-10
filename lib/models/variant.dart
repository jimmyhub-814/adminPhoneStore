class Variants {
  static const idField = 'id';
  static const imageField = 'image';
  static const phoneTypeField = 'phoneType';
  static const phonePriceField = 'phonePrice';
  static const phoneQuantityField = 'phoneQuantity';
  static const phoneDiscountField = 'phoneDiscount';

  String id;
  String phoneType;
  String? image;
  double phonePrice;
  int phoneQuantity;
  double phoneDiscount;

  Variants({
    required this.id,
    this.image,
    required this.phoneType,
    required this.phoneDiscount,
    required this.phonePrice,
    required this.phoneQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      imageField: image,
      phoneTypeField: phoneType,
      phoneQuantityField: phoneQuantity,
      phoneDiscountField: phoneDiscount,
      phonePriceField: phonePrice,
    };
  }

  factory Variants.fromMap(Map<String, dynamic> map) {
    return Variants(
      id: map[idField] as String,
      image: map[imageField]?.toString(),
      phoneType: map[phoneTypeField] as String,
      phoneDiscount: map[phoneDiscountField] as double,
      phonePrice: map[phonePriceField] as double,
      phoneQuantity: map[phoneQuantityField] as int,
    );
  }
}
