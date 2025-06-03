import 'package:flutter/material.dart';
import 'forget_password_screen.dart';

class ForgetPage extends StatefulWidget {
  const ForgetPage({super.key});

  @override
  State<ForgetPage> createState() => _ForgetPageState();
}

class _ForgetPageState extends State<ForgetPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  void _sendResetCode() {
    if (_formKey.currentState?.validate() ?? false) {
      // Burada e-mail ile sıfırlama kodu gönderme işlemini ekleyebilirsiniz.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ForgetPasswordScreen(email: _emailController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Şifre Sıfırlama"),
        leading: BackButton(color: Colors.black),
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
                  color: Color(0xFF78C6F7),
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
                  child: const Text('E-Mail Gönder!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
