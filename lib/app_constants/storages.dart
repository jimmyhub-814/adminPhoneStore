import 'package:firebase_storage/firebase_storage.dart';

class Storages {
  static final carousels = FirebaseStorage.instance.ref().child('carousel'); 
  static final products = FirebaseStorage.instance.ref().child('products');
  
  static Reference carousel(String carouselId) {
    return FirebaseStorage.instance.ref().child('carousel/$carouselId.jpg');
  }
  static Reference category(String categoryId) {
    return FirebaseStorage.instance.ref().child('categories/$categoryId.jpg');
  }

  static Reference product(String id) {
    return FirebaseStorage.instance.ref().child('products/$id.jpg');
  }
  static Reference variant(String id) {
    return FirebaseStorage.instance.ref().child('products/variants/$id.jpg');
  }
}
