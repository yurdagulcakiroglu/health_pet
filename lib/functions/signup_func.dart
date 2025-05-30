import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health_pet/screens/home_page.dart';

class SignUpFunctions {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signUp(
    BuildContext context,
    GlobalKey<FormState> formKey,
    bool agreePersonalData,
    String email,
    String password,
  ) async {
    if (formKey.currentState!.validate() && agreePersonalData) {
      try {
        // Firebase Authentication ile kullanıcı kaydı
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(email: email, password: password);

        // Firestore'a kullanıcı bilgilerini kaydetme
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'email': email,
              // Diğer kullanıcı bilgileri buraya eklenebilir
            });

        // Kayıt başarılı, ana sayfaya yönlendirme
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PetHealthHomePage()),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          _showErrorDialog(context, 'Bu e-posta zaten kayıtlı.');
        } else if (e.code == 'weak-password') {
          _showErrorDialog(context, 'Parola çok zayıf.');
        } else {
          _showErrorDialog(
            context,
            'Kayıt sırasında bir hata oluştu: ${e.message}',
          );
        }
      } catch (e) {
        _showErrorDialog(context, 'Bir hata oluştu: $e');
      }
    } else if (!agreePersonalData) {
      _showErrorDialog(context, 'Lütfen kişisel veri işleme onayını verin.');
    }
  }

  Future<void> signUpWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Kullanıcı Google ile giriş yapmayı iptal etti
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Kullanıcının e-posta doğrulaması yapıldı mı?
      if (!userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
      }

      // Firestore'a kullanıcı bilgilerini kaydetme
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': userCredential.user!.email,
            // Diğer kullanıcı bilgileri buraya eklenebilir
          });

      // Kayıt başarılı, ana sayfaya yönlendirme
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PetHealthHomePage()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        _showErrorDialog(
          context,
          'Bu e-posta ile başka bir giriş yöntemiyle hesap oluşturulmuş.',
        );
      } else {
        _showErrorDialog(
          context,
          'Google ile giriş yaparken bir hata oluştu: ${e.message}',
        );
      }
    } catch (e) {
      _showErrorDialog(context, 'Bir hata oluştu: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
