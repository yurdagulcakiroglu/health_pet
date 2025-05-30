import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pet/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final signInFunctionsProvider = Provider<SignInFunctions>((ref) {
  final authService = ref.read(authServiceProvider);
  return SignInFunctions(authService);
});

class SignInFunctions {
  final AuthService _authService;

  SignInFunctions(this._authService);

  Future<void> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      User? user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      showErrorDialog(context, e.toString());
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      showErrorDialog(context, e.toString());
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Hata"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Tamam"),
            ),
          ],
        );
      },
    );
  }
}
