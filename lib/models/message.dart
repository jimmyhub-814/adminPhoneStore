import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  static const idField = 'id';
  static const senderIdField = 'senderId';
  static const messageField = 'message';
  static const timeField = 'time';
  static const productField = 'product';
  static const statusMessageField = 'statusMessage';

  final String id;
  final String senderId;
  final String message;
  final int time;
  final ProductMessage? product;
  final StatusMessage statusMessage;

  Message({
    required this.id,
    required this.senderId,
    required this.message,
    required this.time,
    required this.statusMessage,
    this.product,
  });

  Map<String, dynamic> toMap() => {
        idField: id,
        senderIdField: senderId,
        messageField: message,
        timeField: time,
        statusMessageField: statusMessage.name,
        productField: product?.toMap(),
      };

  Message copyWith({
    String? id,
    String? senderId,
    String? message,
    int? time,
    Object? product = _unset,
    StatusMessage? statusMessage,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      time: time ?? this.time,
      product: product == _unset ? this.product : product as ProductMessage?,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    final rawTime = map[timeField];
    final int time = rawTime is Timestamp
        ? rawTime.millisecondsSinceEpoch
        : rawTime is int
            ? rawTime
            : 0;

    return Message(
      id: map[idField] ?? '',
      senderId: map[senderIdField] ?? '',
      message: map[messageField] ?? '',
      time: time,
      statusMessage: StatusMessage.values.firstWhere(
        (e) => e.name == map[statusMessageField],
        orElse: () => StatusMessage.failed,
      ),
      product: map[productField] == null
          ? null
          : ProductMessage.fromMap(
              Map<String, dynamic>.from(map[productField]),
            ),
    );
  }

  static const _unset = Object();
}

class ProductMessage {
  static const productIdField = 'productId';
  static const productNameField = 'productName';
  static const productImageField = 'productImage';
  static const productPriceField = 'productPrice';
  String productId;
  String productName;
  String productImage;
  double productPrice;

  ProductMessage({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      productIdField: productId,
      productNameField: productName,
      productImageField: productImage,
      productPriceField: productPrice,
    };
  }

  factory ProductMessage.fromMap(Map<String, dynamic> map) {
    return ProductMessage(
      productId: map[productIdField] as String,
      productName: map[productNameField] as String,
      productImage: map[productImageField] as String,
      productPrice: map[productPriceField] as double,
    );
  }
}

enum StatusMessage {
  sending,
  sent,
  failed,
}
