import 'package:admin/app_constants/auth_helper.dart';
import 'package:admin/app_constants/providers.dart';
import 'package:admin/models/admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class AdminProvider extends ChangeNotifier {
  Admin? _admin;
  Admin? get admin => _admin;
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  
  Future<void> loadInfo() async {
    _isLoading = true;
    notifyListeners();

    _admin = await getAdminInfo();

    _isLoading = false;
    notifyListeners();
  }

  Future<Admin?> getAdminInfo() async {
    final adminDoc = await Collections.admin.doc(AuthHelper.adminId).get();

    if (!adminDoc.exists) {
      print("admin data not found!");
    }

    final admin = Admin.fromMap(adminDoc.data()!);

    return admin;
  }

  Future<void> signOut() async {
    final token = await FirebaseMessaging.instance.getToken();
    final adminRef = Collections.admin.doc(AuthHelper.adminId);

    final snap = await adminRef.get();

    if (snap.exists && token != null) {
      List<String> adminDeviceTokens =
          List<String>.from(snap.data()![Admin.adminDeviceTokensField] ?? []);

      adminDeviceTokens.remove(token);

      await adminRef.update({
        Admin.adminDeviceTokensField: adminDeviceTokens,
      });
    }

    await FirebaseAuth.instance.signOut();
  }
}
