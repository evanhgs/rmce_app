import '../../core/network/app_http_client.dart';
import 'run_models.dart';

class ScoresRepository {
  ScoresRepository({AppHttpClient? httpClient})
      : _httpClient = httpClient ?? AppHttpClient();

  final AppHttpClient _httpClient;

  Future<ScoreModel> submitScore({
    required int routeId,
    required Duration elapsed,
    required RunMetrics metrics,
  }) async {
    final response = await _httpClient.post(
      '/routes/$routeId/score',
      authenticated: true,
      body: {
        'time_seconds': elapsed.inMilliseconds / 1000,
        'max_speed_kmh': metrics.maxSpeedKmh,
        'avg_speed_kmh': metrics.avgSpeedKmh,
        'max_g_force': metrics.maxGForce,
        'max_inclination_degrees': metrics.maxInclinationDegrees,
        'max_sound_db': metrics.maxSoundDb,
      },
    );
    return ScoreModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> uploadSensorDataBulk({
    required int scoreId,
    required List<SensorSample> samples,
  }) async {
    await _httpClient.post(
      '/sensor-data/bulk',
      authenticated: true,
      body: {
        'score_id': scoreId,
        'data': samples.map((sample) => sample.toJson()).toList(growable: false),
      },
    );
  }
}
