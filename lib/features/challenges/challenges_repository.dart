import '../../core/network/app_http_client.dart';
import 'challenge_models.dart';

class ChallengesRepository {
  ChallengesRepository({AppHttpClient? httpClient})
      : _httpClient = httpClient ?? AppHttpClient();

  final AppHttpClient _httpClient;

  Future<ChallengeModel> createChallenge({
    required int routeId,
    int? challengedId,
  }) async {
    final response = await _httpClient.post(
      '/api/challenges',
      authenticated: true,
      body: {
        'route_id': routeId,
        'challenged_id': challengedId,
      },
    );
    return ChallengeModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<ChallengeModel>> getAvailableChallenges() async {
    final response =
        await _httpClient.get('/api/challenges/available', authenticated: true);
    final items = response as List<dynamic>? ?? const [];
    return items
        .map((item) => ChallengeModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ChallengeModel> acceptChallenge(int challengeId) async {
    final response = await _httpClient.post(
      '/api/challenges/$challengeId/accept',
      authenticated: true,
    );
    return ChallengeModel.fromJson(response as Map<String, dynamic>);
  }

  Future<ChallengeModel> completeChallenge({
    required int challengeId,
    double? challengerTime,
    double? challengedTime,
  }) async {
    final response = await _httpClient.post(
      '/api/challenges/$challengeId/complete',
      authenticated: true,
      body: {
        'status': 'completed',
        'challenger_time': challengerTime,
        'challenged_time': challengedTime,
      },
    );
    return ChallengeModel.fromJson(response as Map<String, dynamic>);
  }
}
