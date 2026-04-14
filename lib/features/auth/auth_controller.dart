import 'package:flutter/foundation.dart';

import 'auth_repository.dart';

class AuthState {
  const AuthState({
    required this.isLoading,
    required this.isLoggedIn,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool isLoggedIn;
  final Map<String, dynamic>? user;
  final String? errorMessage;
  final String? successMessage;

  const AuthState.initial()
      : isLoading = false,
        isLoggedIn = false,
        user = null,
        errorMessage = null,
        successMessage = null;

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    Map<String, dynamic>? user,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

class AuthController {
  AuthController({required AuthRepository repository}) : _repository = repository;

  final AuthRepository _repository;
  final ValueNotifier<AuthState> state = ValueNotifier(const AuthState.initial());

  Future<void> initialize() async {
    final isLoggedIn = await _repository.isLoggedIn();
    final user = await _repository.getUser();
    state.value = state.value.copyWith(
      isLoggedIn: isLoggedIn,
      user: user,
      clearError: true,
      clearSuccess: true,
    );
  }

  Future<void> login(String email, String password) async {
    state.value = state.value.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    final result = await _repository.login(email, password);
    if (result['success'] == true) {
      await initialize();
      state.value = state.value.copyWith(
        isLoading: false,
        successMessage: 'Connexion réussie.',
      );
      return;
    }

    state.value = state.value.copyWith(
      isLoading: false,
      errorMessage: result['message']?.toString() ?? 'Connexion impossible.',
    );
  }

  Future<void> register(String username, String email, String password) async {
    state.value = state.value.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    final result = await _repository.register(username, email, password);
    state.value = state.value.copyWith(
      isLoading: false,
      successMessage: result['success'] == true
          ? 'Compte créé. Vous pouvez maintenant vous connecter.'
          : null,
      errorMessage: result['success'] == true
          ? null
          : result['message']?.toString() ?? 'Inscription impossible.',
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state.value = const AuthState.initial();
  }
}
