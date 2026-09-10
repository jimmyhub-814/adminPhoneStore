 
class Cart {
  static const idField = 'id';
  static const variantsIdField = 'variantsId';
  static const quantityField = 'quantity';

  String id;
  String variantsId;
  int quantity;

  Cart({
    required this.id,
    required this.variantsId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      variantsIdField: variantsId,
      quantityField: quantity,
    };
  }

  factory Cart.fromMap(Map<String, dynamic> map) {
    return Cart(
      id: map[idField] as String,
      variantsId: map[variantsIdField] as String,
      quantity: map[quantityField] as int,
    );
  }
}
