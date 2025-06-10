import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:health_pet/functions/signup_func.dart';
import 'package:health_pet/providers/signup_provider.dart';
import 'package:health_pet/screens/signin_screen.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final formState = ref.read(signupFormProvider);
    _emailController = TextEditingController(text: formState.email);
    _passwordController = TextEditingController(text: formState.password);
    _confirmPasswordController = TextEditingController(
      text: formState.confirmPassword,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(signupFormProvider);
    final formNotifier = ref.read(signupFormProvider.notifier);
    final signUpFunctions = SignUpFunctions();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: Colors.black,
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildHeader(),
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
                _buildAgreementCheckbox(formState, formNotifier, context),
                _buildSignUpButton(formState, formNotifier, signUpFunctions),
                _buildSocialLoginButtons(formState, signUpFunctions, context),
                _buildSignInPrompt(formState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: <Widget>[
        FadeInUp(
          duration: const Duration(milliseconds: 1000),
          child: const Text(
            "Kayıt OL",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
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
        const SizedBox(height: 40),
      ],
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
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            notifier.updateEmail(value);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _emailController.selection = TextSelection.fromPosition(
                TextPosition(offset: _emailController.text.length),
              );
            });
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
              borderRadius: BorderRadius.circular(8),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email alanı boş olamaz';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Geçerli bir email adresi girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
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
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: true,
          onChanged: (value) {
            notifier.updatePassword(value);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _passwordController.selection = TextSelection.fromPosition(
                TextPosition(offset: _passwordController.text.length),
              );
            });
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
              borderRadius: BorderRadius.circular(8),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
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
        const SizedBox(height: 20),
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
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocusNode,
          obscureText: true,
          onChanged: (value) {
            notifier.updateConfirmPassword(value);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _confirmPasswordController.selection = TextSelection.fromPosition(
                TextPosition(offset: _confirmPasswordController.text.length),
              );
            });
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
              borderRadius: BorderRadius.circular(8),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
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
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAgreementCheckbox(
    SignupFormState state,
    SignupFormNotifier notifier,
    BuildContext context,
  ) {
    return FadeInUp(
      duration: const Duration(milliseconds: 1450),
      child: Row(
        children: [
          Checkbox(
            value: state.agreePersonalData,
            onChanged: (bool? value) =>
                notifier.toggleAgreement(value ?? false),
            activeColor: const Color(0xFF78C6F7),
          ),
          GestureDetector(
            onTap: () => _showKvkkDialog(context),
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
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton(
    SignupFormState state,
    SignupFormNotifier notifier,
    SignUpFunctions signUpFunctions,
  ) {
    return FadeInUp(
      duration: const Duration(milliseconds: 1500),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: state.isLoading
              ? null
              : () {
                  if (_formKey.currentState?.validate() ?? false) {
                    notifier.setLoading(true);
                    signUpFunctions
                        .signUp(
                          context,
                          _formKey,
                          state.agreePersonalData,
                          state.email,
                          state.password,
                        )
                        .whenComplete(() => notifier.setLoading(false));
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF78C6F7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 0,
          ),
          child: state.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "Kayıt",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButtons(
    SignupFormState state,
    SignUpFunctions signUpFunctions,
    BuildContext context,
  ) {
    return FadeInUp(
      duration: const Duration(milliseconds: 1400),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Text('- VEYA -', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.google,
                    size: 25.0,
                    color: Colors.black54,
                  ),
                  onPressed: state.isLoading
                      ? null
                      : () => signUpFunctions.signUpWithGoogle(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInPrompt(SignupFormState state) {
    return FadeInUp(
      duration: const Duration(milliseconds: 1500),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Zaten bir hesabın var mı? ',
              style: TextStyle(color: Colors.black54),
            ),
            GestureDetector(
              onTap: state.isLoading
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (e) => const SigninScreen()),
                    ),
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
    );
  }

  //kvkk dialog
  Future<void> _showKvkkDialog(BuildContext context) async {
    final kvkkContent = await rootBundle.loadString(
      'assets/kvkk_text/kvkk.txt',
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kişisel Verilerin İşlenmesi'),
          content: SingleChildScrollView(child: Text(kvkkContent)),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
