import '../../services/auth_service.dart';

class AuthRepository {
  AuthRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<Map<String, dynamic>> login(String email, String password) {
    return _authService.login(email, password);
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) {
    return _authService.register(username, email, password);
  }

  Future<void> logout() => _authService.logout();

  Future<bool> isLoggedIn() => _authService.isLoggedIn();

  Future<Map<String, dynamic>?> getUser() => _authService.getUser();
}
