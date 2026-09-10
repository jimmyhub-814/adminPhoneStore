import 'package:cloud_firestore/cloud_firestore.dart';

class UserOrder {
  static const idField = 'id';
  static const orderProductField = 'orderProduct';
  static const userInfoField = 'userInfo';
  static const orderInfoField = 'orderInfo';
  static const statusHistoryField = 'statusHistory';

  String id;
  List<OrderProduct> orderProduct;
  OrderUserInfo userInfo;
  OrderInfo orderInfo;
  List<StatusHistory> statusHistory;

  UserOrder({
    required this.id,
    required this.orderProduct,
    required this.orderInfo,
    required this.userInfo,
    required this.statusHistory,
  });

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      orderProductField: orderProduct.map((e) => e.toMap()).toList(),
      userInfoField: userInfo.toMap(),
      orderInfoField: orderInfo.toMap(),
      statusHistoryField: statusHistory.map((e) => e.toMap()).toList(),
    };
  }

  factory UserOrder.fromMap(Map<String, dynamic> map) {
    return UserOrder(
      id: map[idField] as String,
      orderProduct: (map[orderProductField] as List?)
              ?.map((e) => OrderProduct.fromMap(e))
              .toList() ??
          [],
      orderInfo: OrderInfo.fromMap(map[orderInfoField]),
      userInfo: OrderUserInfo.fromMap(map[userInfoField]),
      statusHistory: (map[statusHistoryField] as List?)
              ?.map((e) => StatusHistory.fromMap(e))
              .toList() ??
          [],
    );
  }
}

class StatusHistory {
  static const statusField = 'status';
  static const timeField = 'time';
  static const updateByField = 'updateBy';

  String status;
  Timestamp time;
  String updateBy;

  StatusHistory({
    required this.status,
    required this.time,
    required this.updateBy,
  });

  Map<String, dynamic> toMap() {
    return {
      statusField: status,
      timeField: time,
      updateByField: updateBy,
    };
  }

  factory StatusHistory.fromMap(Map<String, dynamic> map) {
    return StatusHistory(
      status: map[statusField] ?? '',
      time: map[timeField] ?? '',
      updateBy: map[updateByField] ?? '',
    );
  }
}

class OrderInfo {
  static const orderStatusField = 'orderStatus';
  static const orderNoteField = 'orderNote';
  static const orderDateField = 'orderDate';
  static const lastStatusTimeField = 'lastStatusTime';
  static const methodPaymentField = 'methodPayment';
  static const totalPriceField = 'totalPrice';

  String orderStatus;
  String orderNote;
  Timestamp orderDate;
  Timestamp lastStatusTime;
  String methodPayment;
  double totalPrice;

  OrderInfo({
    required this.orderStatus,
    required this.orderNote,
    required this.lastStatusTime,
    required this.orderDate,
    required this.methodPayment,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      orderStatusField: orderStatus,
      orderNoteField: orderNote,
      orderDateField: orderDate,
      lastStatusTimeField: lastStatusTime,
      methodPaymentField: methodPayment,
      totalPriceField: totalPrice,
    };
  }

  factory OrderInfo.fromMap(Map<String, dynamic> map) {
    return OrderInfo(
      orderStatus: map[orderStatusField] ?? '',
      orderNote: map[orderNoteField] ?? '',
      lastStatusTime: map[lastStatusTimeField] ?? '',
      orderDate: map[orderDateField] ?? '',
      methodPayment: map[methodPaymentField] ?? '',
      totalPrice: (map[totalPriceField] ?? 0).toDouble(),
    );
  }
}

class OrderUserInfo {
  static const userIdField = 'userId';
  static const userNameField = 'userName';
  static const userPhoneField = 'userPhone';
  static const userAddressField = 'userAddress';
  static const userAvatarField = 'userAvatar';

  String userId;
  String userName;
  String userPhone;
  String userAddress;
  String userAvatar;

  OrderUserInfo({
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userAddress,
    required this.userAvatar,
  });

  Map<String, dynamic> toMap() {
    return {
      userIdField: userId,
      userNameField: userName,
      userPhoneField: userPhone,
      userAddressField: userAddress,
      userAvatarField: userAvatar,
    };
  }

  factory OrderUserInfo.fromMap(Map<String, dynamic> map) {
    return OrderUserInfo(
      userId: map[userIdField] ?? '',
      userName: map[userNameField] ?? '',
      userPhone: map[userPhoneField] ?? '',
      userAddress: map[userAddressField] ?? '',
      userAvatar: map[userAddressField] ?? '',
    );
  }
}

class OrderProduct {
  static const idField = 'id';
  static const variantsIdField = 'variantsId';
  static const variantsNameField = 'variantsName';
  static const phoneNameField = 'phoneName';
  static const phonePriceField = 'phonePrice';
  static const phoneDiscountField = 'phoneDiscount';
  static const quantityField = 'quantity';
  static const phoneImageField = 'phoneImage';

  String id;
  String variantsId;
  String variantsName;
  String phoneName;
  double phonePrice;
  double phoneDiscount;
  int quantity;
  String phoneImage;

  OrderProduct({
    required this.id,
    required this.variantsId,
    required this.variantsName,
    required this.phoneName,
    required this.phonePrice,
    required this.phoneDiscount,
    required this.quantity,
    required this.phoneImage,
  });

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      variantsIdField: variantsId,
      variantsNameField: variantsName,
      phoneNameField: phoneName,
      phonePriceField: phonePrice,
      phoneImageField: phoneImage,
      phoneDiscountField: phoneDiscount,
      quantityField: quantity,
    };
  }

  factory OrderProduct.fromMap(Map<String, dynamic> map) {
    return OrderProduct(
      id: map[idField] ?? '',
      variantsId: map[variantsIdField] ?? '',
      variantsName: map[variantsNameField] ?? '',
      phoneName: map[phoneNameField] ?? '',
      phoneDiscount: (map[phoneDiscountField] ?? 0).toDouble(),
      phoneImage: map[phoneImageField] ?? '',
      quantity: map[quantityField] ?? '',
      phonePrice: (map[phonePriceField] ?? 0).toDouble(),
    );
  }
}

enum OrderStatus {
  pending, // Chờ xác nhận
  confirmed, // Chờ giao hàng
  shipping, // Đang giao hàng
  delivered, // Đã giao
  cancelled, // Đã hủy
  returned, // Trả hàng
  reviewed, // Đánh giá
  cancelledByAdmin // Hủy đơn bởi admin
}

enum UpdateBy {
  system,
  admin,
  user,
}
