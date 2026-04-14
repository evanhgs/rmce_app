import '../../core/network/app_http_client.dart';
import 'leaderboard_models.dart';

class LeaderboardsRepository {
  LeaderboardsRepository({AppHttpClient? httpClient})
      : _httpClient = httpClient ?? AppHttpClient();

  final AppHttpClient _httpClient;

  Future<List<LeaderboardEntry>> getRouteLeaderboard(int routeId) async {
    final response = await _httpClient.get(
      '/api/leaderboard/route/$routeId',
      authenticated: true,
    );
    return _parse(response);
  }

  Future<List<LeaderboardEntry>> getGlobalSpeedLeaderboard() async {
    final response = await _httpClient.get(
      '/api/leaderboard/global/speed',
      authenticated: true,
    );
    return _parse(response);
  }

  List<LeaderboardEntry> _parse(dynamic response) {
    final items = response as List<dynamic>? ?? const [];
    return items
        .map((item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
