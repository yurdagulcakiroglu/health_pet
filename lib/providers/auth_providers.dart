import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:health_pet/services/auth.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthService authService(AuthServiceRef ref) => AuthService();

@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) {
  return ref.watch(authServiceProvider).authStateChanges;
}

class AuthState {
  final String email;
  final String password;
  final String confirmPassword;
  final bool rememberPassword;
  final bool isLoading;
  final String? error;
  final bool emailValid;
  final bool passwordValid;
  final bool agreePersonalData;
  final bool confirmPasswordValid;
  final String name;
  final String surname;
  final bool nameValid;
  final bool surnameValid;

  AuthState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.rememberPassword = true,
    this.isLoading = false,
    this.error,
    this.emailValid = false,
    this.passwordValid = false,
    this.agreePersonalData = false,
    this.confirmPasswordValid = false,
    this.name = '',
    this.surname = '',
    this.nameValid = false,
    this.surnameValid = false,
  });

  bool get isFormValid =>
      emailValid &&
      passwordValid &&
      confirmPasswordValid &&
      nameValid &&
      surnameValid;

  bool get canSignUp => isFormValid && agreePersonalData && !isLoading;

  AuthState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    bool? rememberPassword,
    bool? agreePersonalData,
    bool? isLoading,
    String? error,
    bool? emailValid,
    bool? passwordValid,
    bool? confirmPasswordValid,
    String? name,
    String? surname,
    bool? nameValid,
    bool? surnameValid,
  }) {
    return AuthState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      rememberPassword: rememberPassword ?? this.rememberPassword,
      agreePersonalData: agreePersonalData ?? this.agreePersonalData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      emailValid: emailValid ?? this.emailValid,
      passwordValid: passwordValid ?? this.passwordValid,
      confirmPasswordValid: confirmPasswordValid ?? this.confirmPasswordValid,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      nameValid: nameValid ?? this.nameValid,
      surnameValid: surnameValid ?? this.surnameValid,
    );
  }
}

@riverpod
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    return AuthState();
  }

  final emailProvider = StateProvider<String>((ref) => '');
  final passwordProvider = StateProvider<String>((ref) => '');

  void updateEmail(String email) {
    final emailValid = _validateEmail(email);
    state = state.copyWith(email: email, emailValid: emailValid, error: null);
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void updatePassword(String password) {
    final passwordValid = password.length >= 6;
    state = state.copyWith(
      password: password,
      passwordValid: passwordValid,
      error: null,
    );

    if (state.confirmPassword.isNotEmpty) {
      updateConfirmPassword(state.confirmPassword);
    }
  }

  void updateConfirmPassword(String password) {
    final confirmValid = password == state.password && password.isNotEmpty;
    state = state.copyWith(
      confirmPassword: password,
      confirmPasswordValid: confirmValid,
      error: null,
    );
  }

  void updateName(String name) {
    final nameValid = name.trim().length >= 2;
    state = state.copyWith(name: name, nameValid: nameValid, error: null);
  }

  void updateSurname(String surname) {
    final surnameValid = surname.trim().length >= 2;
    state = state.copyWith(
      surname: surname,
      surnameValid: surnameValid,
      error: null,
    );
  }

  void toggleRememberPassword() {
    state = state.copyWith(rememberPassword: !state.rememberPassword);
  }

  void toggleAgreePersonalData() {
    state = state.copyWith(agreePersonalData: !state.agreePersonalData);
  }

  Future<void> signInWithEmail(BuildContext context) async {
    if (!state.emailValid || !state.passwordValid || state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final userCredential = await ref
          .read(authServiceProvider)
          .signInWithEmailAndPassword(
            email: state.email,
            password: state.password,
          );
      if (userCredential.user != null) {
        _navigateToHome(context);
      } else {
        throw AuthException('no-user', 'Kullanıcı bilgisi alınamadı');
      }
    } on AuthException catch (e) {
      _handleError(context, e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signUp(BuildContext context) async {
    if (!state.canSignUp) {
      _handleError(context, 'Lütfen tüm alanları doğru şekilde doldurun');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final userCredential = await ref
          .read(authServiceProvider)
          .signUpWithEmailAndPassword(
            email: state.email,
            password: state.password,
            name: state.name,
            surname: state.surname,
          );

      if (userCredential.user != null) {
        _navigateToHome(context);
      } else {
        throw AuthException(
          'no-user',
          'Kayıt sırasında kullanıcı oluşturulamadı',
        );
      }
    } on AuthException catch (e) {
      _handleError(context, e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final userCredential = await ref
          .read(authServiceProvider)
          .signInWithGoogle();
      if (userCredential.user != null) {
        _navigateToHome(context);
      } else {
        throw AuthException('no-user', 'Google ile giriş başarısız');
      }
    } on AuthException catch (e) {
      _handleError(context, e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void _navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  void _handleError(BuildContext context, String error) {
    state = state.copyWith(error: error);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    });
  }

  Future<void> signOut(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(authServiceProvider).signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } on AuthException catch (e) {
      _handleError(context, e.toString());
    } catch (_) {
      _handleError(context, 'Çıkış yapılırken bir hata oluştu');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
