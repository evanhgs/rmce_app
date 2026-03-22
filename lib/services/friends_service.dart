import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class FriendInfo {
  final int id;
  final String username;
  final String email;
  final String status;

  const FriendInfo({
    required this.id,
    required this.username,
    required this.email,
    required this.status,
  });

  factory FriendInfo.fromJson(Map<String, dynamic> json) => FriendInfo(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String,
        status: json['status'] as String,
      );
}

class PendingRequest {
  final int friendshipId;
  final int id;
  final String username;
  final String email;
  final String status;

  const PendingRequest({
    required this.friendshipId,
    required this.id,
    required this.username,
    required this.email,
    required this.status,
  });

  factory PendingRequest.fromJson(Map<String, dynamic> json) => PendingRequest(
        friendshipId: json['friendship_id'] as int,
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String,
        status: json['status'] as String,
      );
}

class FriendsService {
  static final FriendsService _instance = FriendsService._internal();
  factory FriendsService() => _instance;
  FriendsService._internal();

  final AuthService _auth = AuthService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _auth.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<FriendInfo>> getFriends() async {
    try {
      final resp = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/friends'),
        headers: await _authHeaders(),
      );
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        return list.map((e) => FriendInfo.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<PendingRequest>> getPendingRequests() async {
    try {
      final resp = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/friends/pending'),
        headers: await _authHeaders(),
      );
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        return list.map((e) => PendingRequest.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> addFriend(String username) async {
    try {
      final resp = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/friends/add/$username'),
        headers: await _authHeaders(),
      );
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> acceptFriend(int friendshipId) async {
    try {
      final resp = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/friends/accept/$friendshipId'),
        headers: await _authHeaders(),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectFriend(int friendshipId) async {
    try {
      final resp = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/friends/reject/$friendshipId'),
        headers: await _authHeaders(),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
