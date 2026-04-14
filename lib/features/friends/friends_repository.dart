import '../../core/network/app_http_client.dart';
import 'friends_models.dart';

class FriendsRepository {
  FriendsRepository({AppHttpClient? httpClient})
      : _httpClient = httpClient ?? AppHttpClient();

  final AppHttpClient _httpClient;

  Future<List<FriendModel>> getFriends() async {
    final response = await _httpClient.get('/friends', authenticated: true);
    final items = response as List<dynamic>? ?? const [];
    return items
        .map((item) => FriendModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<FriendRequestModel>> getPendingRequests() async {
    final response =
        await _httpClient.get('/friends/pending', authenticated: true);
    final items = response as List<dynamic>? ?? const [];
    return items
        .map(
          (item) => FriendRequestModel.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<void> addFriend(String username) async {
    await _httpClient.post('/friends/add/$username', authenticated: true);
  }

  Future<void> accept(int friendshipId) async {
    await _httpClient.put('/friends/accept/$friendshipId', authenticated: true);
  }

  Future<void> reject(int friendshipId) async {
    await _httpClient.put('/friends/reject/$friendshipId', authenticated: true);
  }
}
