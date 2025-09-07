import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login failed. Please try again.";

      if (e.code == 'user-not-found') {
        message = "Invalid email. Please check your email address.";
      } else if (e.code == 'wrong-password') {
        message = "Invalid password. Please try again.";
      } else if (e.code == 'invalid-email') {
        message = "Email format is incorrect.";
      } else if (e.code == 'user-disabled') {
        message = "This account has been disabled.";
      }

      throw message;
    } catch (e) {
      throw ("Something went wrong. Try again later.");
    }
  }


  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners(); /// ui refersh
  }
}
