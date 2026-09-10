import 'package:flutter/material.dart';

class UserApp extends ChangeNotifier {
  static const idField = 'id';
  static const userAccountField = 'userAccount';
  static const userAvatarField = 'userAvatar';
  static const userNameField = 'userName';
  static const userGenderField = 'userGender';
  static const userDateField = 'userDate';
  static const userDeviceTokensField = 'userDeviceTokens';
  static const isCompletedField = 'isCompleted';
  static const shippingInfoField = 'shippingInfo';

  String id;
  String userAvatar;
  String userName;
  String userGender;
  String userDate;
  String userAccount;
  List<String> userDeviceTokens;
  List<ShippingInfo> shippingInfo;
  bool isCompleted;

  UserApp({
    required this.id,
    required this.userAvatar,
    required this.userName,
    required this.userGender,
    required this.userDate,
    required this.userDeviceTokens,
    required this.shippingInfo,
    required this.userAccount,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      userAvatarField: userAvatar,
      userNameField: userName,
      userGenderField: userGender,
      userDateField: userDate,
      userDeviceTokensField: userDeviceTokens,
      shippingInfoField: shippingInfo.map((e) => e.toMap()).toList(),
      userAccountField: userAccount,
      isCompletedField: isCompleted,
    };
  }

  factory UserApp.fromMap(Map<String, dynamic> map) {
    return UserApp(
      id: (map[idField] as String?) ?? '',
      userAvatar: (map[userAvatarField] as String?) ?? '',
      userName: (map[userNameField] as String?) ?? '',
      userGender: (map[userGenderField] as String?) ?? '',
      userDate: (map[userDateField] as String?) ?? '',
      userAccount: (map[userAccountField] as String?) ?? '',
      userDeviceTokens: (map[userDeviceTokensField] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      shippingInfo: (map[shippingInfoField] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map(
            (v) => ShippingInfo.fromMap(
              Map<String, dynamic>.from(v),
            ),
          )
          .toList(),
      isCompleted: (map[isCompletedField] as bool?) ?? false,
    );
  }
}

class ShippingInfo {
  static const idField = 'id';
  static const fullNameField = 'fullName';
  static const phoneField = 'phone';
  static const addressField = 'address';

  String id;
  String fullName;
  String phone;
  String address;

  ShippingInfo({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      fullNameField: fullName,
      addressField: address,
      phoneField: phone,
    };
  }

  factory ShippingInfo.fromMap(Map<String, dynamic> map) {
    return ShippingInfo(
      id: (map[idField] as String?) ?? '',
      fullName: (map[fullNameField] as String?) ?? '',
      phone: (map[phoneField] as String?) ?? '',
      address: (map[addressField] as String?) ?? '',
    );
  }
}
