import 'package:flutter/material.dart';

class Admin extends ChangeNotifier {
  static const idField = 'id';
  static const emailField = 'email';
  static const nameField = 'name';
  static const adminDeviceTokensField = 'adminDeviceTokens';

  String id;
  String email;
  String name;
  List<String> adminDeviceTokens;

  Admin({
    required this.id,
    required this.email,
    required this.name,
    required this.adminDeviceTokens,
  });

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      emailField: email,
      nameField: name,
      adminDeviceTokensField: adminDeviceTokens,
    };
  }

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map[idField] as String,
      email: map[emailField] as String,
      name: map[nameField] as String,
      adminDeviceTokens: (map[adminDeviceTokensField] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
