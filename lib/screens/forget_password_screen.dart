import 'package:flutter/material.dart';

class ForgetPasswordScreen extends StatefulWidget {
  final String email;

  const ForgetPasswordScreen({super.key, required this.email});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  void _resetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      final newPassword = _newPasswordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (newPassword == confirmPassword) {
        // TODO: Şifreyi değiştirme API çağrısı
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifreniz başarıyla güncellendi!')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Şifreler eşleşmiyor!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Şifre Belirle"),
        leading: BackButton(color: Colors.black),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Yeni Şifre Belirle',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF78C6F7),
                ),
              ),
              const SizedBox(height: 25),
              TextFormField(
                controller: _codeController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen sıfırlama kodunu girin!';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Sıfırlama Kodu',
                  hintText: 'Mailinize gelen kod',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yeni şifrenizi girin!';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  hintText: 'Yeni şifreniz',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şifrenizi doğrulayın!';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Şifreyi Doğrula',
                  hintText: 'Yukarıdaki şifreyi tekrar yazın',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _resetPassword,
                  child: const Text('Şifreyi Yenile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
