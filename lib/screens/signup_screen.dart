import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:health_pet/functions/signup_func.dart';
import 'package:health_pet/providers/signup_provider.dart';
import 'package:health_pet/screens/signin_screen.dart';

class SignupPage extends ConsumerWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(signupFormProvider);
    final formNotifier = ref.read(signupFormProvider.notifier);
    final _formKey = GlobalKey<FormState>();
    final signUpFunctions = SignUpFunctions();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                children: <Widget>[
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: const Text(
                      "Kayıt OL",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1200),
                    child: Text(
                      "Hadi bir hesap oluştur!",
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    FadeInUp(
                      duration: const Duration(milliseconds: 1200),
                      child: _buildEmailInput(formNotifier, formState),
                    ),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1300),
                      child: _buildPasswordInput(formNotifier, formState),
                    ),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1400),
                      child: _buildConfirmPasswordInput(
                        formNotifier,
                        formState,
                      ),
                    ),
                  ],
                ),
              ),
              FadeInUp(
                duration: const Duration(milliseconds: 1450),
                child: Row(
                  children: [
                    Checkbox(
                      value: formState.agreePersonalData,
                      onChanged: (bool? value) {
                        formNotifier.toggleAgreement(value ?? false);
                      },
                      activeColor: const Color(0xFF78C6F7),
                    ),
                    GestureDetector(
                      onTap: () {
                        _showKvkkDialog(context);
                      },
                      child: const Text(
                        'Kişisel verilerin ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF78C6F7),
                        ),
                      ),
                    ),
                    const Text(
                      'işlenmesini kabul ediyorum.',
                      style: TextStyle(color: Colors.black45),
                    ),
                  ],
                ),
              ),
              FadeInUp(
                duration: const Duration(milliseconds: 1500),
                child: Container(
                  padding: const EdgeInsets.only(top: 3, left: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: const Border(
                      bottom: BorderSide(color: Colors.black),
                      top: BorderSide(color: Colors.black),
                      left: BorderSide(color: Colors.black),
                      right: BorderSide(color: Colors.black),
                    ),
                  ),
                  child: MaterialButton(
                    minWidth: double.infinity,
                    height: 60,
                    onPressed: formState.isLoading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              formNotifier.setLoading(true);
                              signUpFunctions
                                  .signUp(
                                    context,
                                    _formKey,
                                    formState.agreePersonalData,
                                    formState.email,
                                    formState.password,
                                  )
                                  .whenComplete(() {
                                    formNotifier.setLoading(false);
                                  });
                            }
                          },
                    color: const Color(0xFF78C6F7),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: formState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Kayıt",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
              ),
              FadeInUp(
                duration: const Duration(milliseconds: 1400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.google,
                          size: 25.0,
                          color: Colors.black54,
                        ),
                        onPressed: formState.isLoading
                            ? null
                            : () {
                                signUpFunctions.signUpWithGoogle(context);
                              },
                      ),
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.apple,
                          size: 30.0,
                          color: Colors.black54,
                        ),
                        onPressed: formState.isLoading
                            ? null
                            : () {
                                // Apple ile giriş fonksiyonu
                              },
                      ),
                    ],
                  ),
                ),
              ),
              FadeInUp(
                duration: const Duration(milliseconds: 1500),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Zaten bir hesabın var mı? ',
                      style: TextStyle(color: Colors.black45),
                    ),
                    GestureDetector(
                      onTap: formState.isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (e) => const SigninScreen(),
                                ),
                              );
                            },
                      child: const Text(
                        'Giriş Yap',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA1EF7A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInput(SignupFormNotifier notifier, SignupFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          "Email",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          initialValue: state.email,
          onChanged: notifier.updateEmail,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email alanı boş olamaz';
            }
            return null;
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildPasswordInput(
    SignupFormNotifier notifier,
    SignupFormState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          "Parola",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          initialValue: state.password,
          onChanged: notifier.updatePassword,
          obscureText: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Parola alanı boş olamaz';
            }
            if (value.length < 6) {
              return 'Parola en az 6 karakter olmalıdır';
            }
            return null;
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildConfirmPasswordInput(
    SignupFormNotifier notifier,
    SignupFormState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          "Parola Tekrar",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          initialValue: state.confirmPassword,
          onChanged: notifier.updateConfirmPassword,
          obscureText: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Parola tekrar alanı boş olamaz';
            }
            if (value != state.password) {
              return 'Parolalar eşleşmiyor';
            }
            return null;
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Future<void> _showKvkkDialog(BuildContext context) async {
    final kvkkContent = await rootBundle.loadString(
      'assets/kvkk_text/kvkk.txt',
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kişisel Verilerin İşlenmesi'),
          content: SingleChildScrollView(
            child: ListBody(children: <Widget>[Text(kvkkContent)]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
