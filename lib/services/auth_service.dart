import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  void _logRequest(String method, String url, Map<String, dynamic> body) {
    if (AppConfig.isDev) {
      debugPrint('┌── [AuthService] $method $url');
      debugPrint('└── body: ${jsonEncode(body)}');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = '${AppConfig.apiBaseUrl}/auth/login';
    _logRequest('POST', url, {'email': email, 'password': '***'});
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        await _saveToken(data['token'] as String);
        await _saveUser(data['user'] as Map<String, dynamic>);
        return {'success': true, 'user': data['user']};
      } else {
        final message =
            data['message'] ?? data['error'] ?? 'Identifiants incorrects';
        return {'success': false, 'message': message.toString()};
      }
    } catch (e) {
      return {'success': false, 'message': 'Impossible de joindre le serveur'};
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    final url = '${AppConfig.apiBaseUrl}/auth/register';
    _logRequest(
        'POST', url, {'username': username, 'email': email, 'password': '***'});
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'username': username, 'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      } else {
        final message = data['message'] ??
            data['error'] ??
            'Erreur lors de l\'inscription';
        return {'success': false, 'message': message.toString()};
      }
    } catch (e) {
      return {'success': false, 'message': 'Impossible de joindre le serveur'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }
}
