import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_pet/screens/signin_screen.dart';
import 'package:health_pet/theme/app_colors.dart';

class ForgetPage extends StatefulWidget {
  const ForgetPage({super.key});

  @override
  State<ForgetPage> createState() => _ForgetPageState();
}

class _ForgetPageState extends State<ForgetPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  void _sendResetCode() async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifre sıfırlama e-postası gönderildi')),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SigninScreen()),
        );
      } on FirebaseAuthException catch (e) {
        String message = 'Bir hata oluştu.';
        if (e.code == 'user-not-found') {
          message = 'Bu e-posta ile kayıtlı bir kullanıcı bulunamadı.';
        } else if (e.code == 'invalid-email') {
          message = 'Geçerli bir e-posta adresi girin.';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Şifre Sıfırlama"),
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Şifremi Unuttum',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryColor, // secondaryColor
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen E-Mail adresinizi girin!';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'E-Mail Adresiniz',
                  hintText: 'ornek@email.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendResetCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryColor, // ✅ primaryColor
                    foregroundColor: Colors.black, // Yazı rengi
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'E-Mail Gönder!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
