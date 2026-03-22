import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class FriendLocation {
  final int userId;
  final double lat;
  final double lng;
  final int timestamp; // unix seconds

  const FriendLocation({
    required this.userId,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  factory FriendLocation.fromJson(Map<String, dynamic> json) => FriendLocation(
        userId: json['user_id'] as int,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        timestamp: json['timestamp'] as int,
      );
}

class GeoWebSocketService {
  static final GeoWebSocketService _instance = GeoWebSocketService._internal();
  factory GeoWebSocketService() => _instance;
  GeoWebSocketService._internal();

  WebSocketChannel? _channel;
  bool _connected = false;

  final _locationController = StreamController<FriendLocation>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<FriendLocation> get locationStream => _locationController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _connected;

  /// Coupe et reconnecte — utile quand la liste d'amis a changé.
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 300));
    await connect();
  }

  Future<void> connect() async {
    if (_connected) return;

    final token = await AuthService().getToken();
    if (token == null) return;

    try {
      final uri = Uri.parse('${AppConfig.geoServiceUrl}/ws?token=$token');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connected = true;
      _connectionController.add(true);

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            _locationController.add(FriendLocation.fromJson(json));
          } catch (_) {}
        },
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[GeoWS] Connexion échouée: $e');
      _connected = false;
    }
  }

  void sendLocation(double lat, double lng) {
    if (!_connected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({'lat': lat, 'lng': lng}));
    } catch (_) {}
  }

  void _onDisconnected() {
    _connected = false;
    _connectionController.add(false);
  }

  void disconnect() {
    _channel?.sink.close();
    _onDisconnected();
    _channel = null;
  }
}
