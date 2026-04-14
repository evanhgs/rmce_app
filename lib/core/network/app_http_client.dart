import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import 'api_exception.dart';

class AppHttpClient {
  AppHttpClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final AuthService _authService = AuthService();

  Future<dynamic> get(
    String path, {
    bool authenticated = false,
    Map<String, dynamic>? query,
  }) {
    return _send(
      'GET',
      path,
      authenticated: authenticated,
      query: query,
    );
  }

  Future<dynamic> post(
    String path, {
    bool authenticated = false,
    Object? body,
    Map<String, dynamic>? query,
  }) {
    return _send(
      'POST',
      path,
      authenticated: authenticated,
      body: body,
      query: query,
    );
  }

  Future<dynamic> put(
    String path, {
    bool authenticated = false,
    Object? body,
    Map<String, dynamic>? query,
  }) {
    return _send(
      'PUT',
      path,
      authenticated: authenticated,
      body: body,
      query: query,
    );
  }

  Future<dynamic> delete(
    String path, {
    bool authenticated = false,
    Map<String, dynamic>? query,
  }) {
    return _send(
      'DELETE',
      path,
      authenticated: authenticated,
      query: query,
    );
  }

  Future<dynamic> _send(
    String method,
    String path, {
    bool authenticated = false,
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path').replace(
      queryParameters: query == null
          ? null
          : {
              for (final entry in query.entries)
                if (entry.value != null) entry.key: entry.value.toString(),
            },
    );
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authenticated) {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw ApiException('Session expirée. Merci de vous reconnecter.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    late final http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        case 'PUT':
          response = await _client.put(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
        default:
          throw ApiException('Méthode HTTP non gérée: $method');
      }
    } catch (_) {
      final message = AppConfig.usesLocalEmulatorNetwork
          ? 'Impossible de joindre ${AppConfig.apiBaseUrl}. '
          'Si vous testez sur un vrai téléphone, ne pointez pas vers 10.0.2.2.'
          : 'Impossible de joindre ${AppConfig.apiBaseUrl}.';
      throw ApiException(message);
    }

    if (response.statusCode == 401) {
      await _authService.logout();
      throw ApiException(
        'Votre session a expiré. Merci de vous reconnecter.',
        statusCode: 401,
      );
    }

    final bodyText = response.body.trim();
    final decoded = bodyText.isEmpty ? null : jsonDecode(bodyText);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded is Map<String, dynamic>
        ? (decoded['message'] ?? decoded['error'] ?? 'Erreur serveur')
        : 'Erreur serveur';
    throw ApiException(
      message.toString(),
      statusCode: response.statusCode,
    );
  }
}
