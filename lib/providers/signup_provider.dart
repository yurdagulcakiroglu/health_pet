import 'package:flutter_riverpod/flutter_riverpod.dart';

// Form state'ini yönetecek provider
final signupFormProvider =
    StateNotifierProvider<SignupFormNotifier, SignupFormState>((ref) {
      return SignupFormNotifier();
    });

class SignupFormState {
  final String email;
  final String password;
  final String confirmPassword;
  final bool agreePersonalData;
  final bool isLoading;

  SignupFormState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.agreePersonalData = false,
    this.isLoading = false,
  });

  SignupFormState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    bool? agreePersonalData,
    bool? isLoading,
  }) {
    return SignupFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      agreePersonalData: agreePersonalData ?? this.agreePersonalData,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SignupFormNotifier extends StateNotifier<SignupFormState> {
  SignupFormNotifier() : super(SignupFormState());

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password);
  }

  void updateConfirmPassword(String confirmPassword) {
    state = state.copyWith(confirmPassword: confirmPassword);
  }

  void toggleAgreement(bool value) {
    state = state.copyWith(agreePersonalData: value);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }
}
