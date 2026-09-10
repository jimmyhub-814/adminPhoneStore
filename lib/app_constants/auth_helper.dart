import 'package:firebase_auth/firebase_auth.dart';

class AuthHelper {
  AuthHelper._();

  static String get adminId => FirebaseAuth.instance.currentUser!.uid;

  static User? get currentAdmin => FirebaseAuth.instance.currentUser;

  static bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;
}
