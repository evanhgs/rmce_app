import '../../core/network/app_http_client.dart';
import 'route_models.dart';

class RoutesRepository {
  RoutesRepository({AppHttpClient? httpClient})
      : _httpClient = httpClient ?? AppHttpClient();

  final AppHttpClient _httpClient;

  Future<List<RouteModel>> getPublicRoutes() async {
    final response = await _httpClient.get('/routes/public', authenticated: true);
    return _parseRoutes(response);
  }

  Future<List<RouteModel>> getRoutes({
    int? userId,
    bool? isPublic,
  }) async {
    final response = await _httpClient.get(
      '/routes',
      authenticated: true,
      query: {
        'user_id': userId,
        'is_public': isPublic,
      },
    );
    return _parseRoutes(response);
  }

  Future<List<RouteModel>> getRoutesForUser(int userId) async {
    final response = await _httpClient.get(
      '/routes/user/$userId',
      authenticated: true,
    );
    return _parseRoutes(response);
  }

  Future<RouteModel> createRoute(
    RouteDraft draft, {
    List<RoutePathPoint>? points,
    double? distanceMeters,
  }) async {
    final response = await _httpClient.post(
      '/routes',
      authenticated: true,
      body: draft.toApiPayload(
        customPoints: points,
        customDistanceMeters: distanceMeters,
      ),
    );
    return RouteModel.fromJson(response as Map<String, dynamic>);
  }

  Future<RouteModel> updateRoute(int routeId, RouteDraft draft) async {
    final response = await _httpClient.put(
      '/routes/$routeId',
      authenticated: true,
      body: draft.toApiPayload(),
    );
    return RouteModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteRoute(int routeId) async {
    await _httpClient.delete('/routes/$routeId', authenticated: true);
  }

  List<RouteModel> _parseRoutes(dynamic response) {
    final items = response as List<dynamic>? ?? const [];
    return items
        .map((item) => RouteModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
