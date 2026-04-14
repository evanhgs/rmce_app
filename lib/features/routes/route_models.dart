import 'dart:convert';

import 'package:latlong2/latlong.dart';

class RoutePathPoint {
  const RoutePathPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  LatLng get latLng => LatLng(latitude, longitude);

  List<double> toGeoJsonCoordinate() => [longitude, latitude];

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  factory RoutePathPoint.fromJson(Map<String, dynamic> json) {
    return RoutePathPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  factory RoutePathPoint.fromCoordinate(List<dynamic> coordinate) {
    return RoutePathPoint(
      latitude: (coordinate[1] as num).toDouble(),
      longitude: (coordinate[0] as num).toDouble(),
    );
  }
}

class RouteDraft {
  const RouteDraft({
    required this.name,
    required this.description,
    required this.isPublic,
    required this.points,
  });

  final String name;
  final String description;
  final bool isPublic;
  final List<RoutePathPoint> points;

  double get distanceMeters {
    const calculator = Distance();
    if (points.length < 2) {
      return 0;
    }

    var total = 0.0;
    for (var index = 1; index < points.length; index += 1) {
      total += calculator(
        points[index - 1].latLng,
        points[index].latLng,
      );
    }
    return total;
  }

  Map<String, dynamic> toApiPayload({
    List<RoutePathPoint>? customPoints,
    double? customDistanceMeters,
  }) {
    final payloadPoints = customPoints ?? points;
    return {
      'name': name,
      'description': description.isEmpty ? null : description,
      'is_public': isPublic,
      'path_data': {
        'type': 'LineString',
        'coordinates': payloadPoints
            .map((point) => point.toGeoJsonCoordinate())
            .toList(growable: false),
      },
      'distance_meters': customDistanceMeters ?? distanceMeters,
    };
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'isPublic': isPublic,
        'points': points.map((point) => point.toJson()).toList(growable: false),
      };

  factory RouteDraft.fromJson(Map<String, dynamic> json) {
    return RouteDraft(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isPublic: json['isPublic'] as bool? ?? false,
      points: (json['points'] as List<dynamic>? ?? const [])
          .map(
            (point) => RoutePathPoint.fromJson(point as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  String encode() => jsonEncode(toJson());

  factory RouteDraft.decode(String raw) =>
      RouteDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

class RouteModel {
  const RouteModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.isPublic,
    required this.points,
    required this.distanceMeters,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int userId;
  final String name;
  final String description;
  final bool isPublic;
  final List<RoutePathPoint> points;
  final double distanceMeters;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<LatLng> get polyline => points.map((point) => point.latLng).toList();

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final pathData = (json['path_data'] as Map<String, dynamic>?) ?? const {};
    final coordinates = pathData['coordinates'] as List<dynamic>? ?? const [];
    return RouteModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String? ?? 'Parcours',
      description: json['description'] as String? ?? '',
      isPublic: json['is_public'] as bool? ?? false,
      points: coordinates
          .map((coordinate) => RoutePathPoint.fromCoordinate(coordinate as List))
          .toList(growable: false),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
