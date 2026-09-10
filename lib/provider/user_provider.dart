import 'package:admin/app_constants/providers.dart';
import 'package:admin/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  Future<UserApp?> getUserInfo(String id) async {
    final userDoc = await Collections.users.doc(id).get();

    if (!userDoc.exists) {
      print("User data not found!");
    }

    final user = UserApp.fromMap(userDoc.data()!);

    return user;
  }

  Future<void> signOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    final userRef = Collections.users.doc(user.uid);

    final snap = await userRef.get();

    if (snap.exists && token != null) {
      List<String> userDeviceTokens =
          List<String>.from(snap.data()![UserApp.userDeviceTokensField] ?? []);

      userDeviceTokens.remove(token);

      await userRef.update({
        UserApp.userDeviceTokensField: userDeviceTokens,
      });
    }

    await FirebaseAuth.instance.signOut();
  }
}
