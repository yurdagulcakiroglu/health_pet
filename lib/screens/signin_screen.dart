import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:health_pet/providers/auth_providers.dart';
import 'package:health_pet/screens/signup_screen.dart';
import 'package:health_pet/screens/forget_page.dart';

class SigninScreen extends ConsumerStatefulWidget {
  const SigninScreen({super.key});

  @override
  ConsumerState<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends ConsumerState<SigninScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authControllerProvider);
    _emailController = TextEditingController(text: authState.email);
    _passwordController = TextEditingController(text: authState.password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            _buildHeader(),
                            _buildLoginForm(
                              authState,
                              authController,
                              context,
                              _emailController,
                              _passwordController,
                              _emailFocusNode,
                              _passwordFocusNode,
                            ),
                            _buildSocialLogin(ref, context),
                            _buildSignUpPrompt(context),
                          ],
                        ),
                        _buildBottomImage(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 1000),
          child: const Text(
            "Giriş Yap",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        FadeInUp(
          duration: const Duration(milliseconds: 1200),
          child: Text(
            "Hesabına giriş yap",
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(
    AuthState state,
    AuthController controller,
    BuildContext context,
    TextEditingController emailController,
    TextEditingController passwordController,
    FocusNode emailFocusNode,
    FocusNode passwordFocusNode,
  ) {
    return FadeInUp(
      duration: const Duration(milliseconds: 1400),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            _buildEmailField(
              state,
              controller,
              emailController,
              emailFocusNode,
              context,
            ),
            const SizedBox(height: 20),
            _buildPasswordField(
              state,
              controller,
              passwordController,
              passwordFocusNode,
              context,
            ),
            const SizedBox(height: 10),
            _buildRememberForgotRow(state, controller, context),
            const SizedBox(height: 30),
            _buildLoginButton(state, controller, context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField(
    AuthState state,
    AuthController controller,
    TextEditingController controllerField,
    FocusNode focusNode,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Email",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controllerField,
          focusNode: focusNode,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            controller.updateEmail(value);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controllerField.selection = TextSelection.fromPosition(
                TextPosition(offset: controllerField.text.length),
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
            errorText: state.email.isNotEmpty && !state.emailValid
                ? 'Geçerli bir email girin'
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    AuthState state,
    AuthController controller,
    TextEditingController controllerField,
    FocusNode focusNode,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Parola",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controllerField,
          focusNode: focusNode,
          obscureText: true,
          onChanged: (value) {
            controller.updatePassword(value);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controllerField.selection = TextSelection.fromPosition(
                TextPosition(offset: controllerField.text.length),
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
            errorText: state.password.isNotEmpty && !state.passwordValid
                ? 'Şifre en az 6 karakter olmalı'
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRememberForgotRow(
    AuthState state,
    AuthController controller,
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: state.rememberPassword,
              onChanged: (_) => controller.toggleRememberPassword(),
              activeColor: const Color(0xFF78C6F7),
            ),
            const Text('Beni Hatırla', style: TextStyle(color: Colors.black54)),
          ],
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ForgetPage()),
          ),
          child: const Text(
            'Şifremi Unuttum?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF78C6F7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(
    AuthState state,
    AuthController controller,
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: state.isSignInFormValid
            ? () => controller.signInWithEmail(context)
            : null,
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
                "Giriş Yap",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
      ),
    );
  }

  Widget _buildSocialLogin(WidgetRef ref, BuildContext context) {
    final authController = ref.read(authControllerProvider.notifier);
    final isLoading = ref.watch(authControllerProvider).isLoading;
    return FadeInUp(
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
              onPressed: isLoading
                  ? null
                  : () {
                      authController.signInWithGoogle(context);
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpPrompt(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 1500),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Hesabın yok mu? ',
            style: TextStyle(color: Colors.black54),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (e) => const SignupPage()),
            ),
            child: const Text(
              'Kayıt Ol',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF78C6F7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomImage() {
    return SizedBox(
      width: double.infinity,
      height: 230,
      child: Image.asset("assets/images/signin.png", fit: BoxFit.cover),
    );
  }
}
