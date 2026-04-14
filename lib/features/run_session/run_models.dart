import 'dart:convert';

import '../routes/route_models.dart';

enum RunSessionPhase { idle, running, paused, saving, completed, error }

enum GpsQuality { excellent, good, degraded, poor }

class ScoreModel {
  const ScoreModel({
    required this.id,
    required this.routeId,
    required this.userId,
    required this.timeSeconds,
    required this.maxSpeedKmh,
    required this.avgSpeedKmh,
    required this.maxGForce,
    required this.maxInclinationDegrees,
    required this.maxSoundDb,
    required this.createdAt,
  });

  final int id;
  final int routeId;
  final int userId;
  final double timeSeconds;
  final double? maxSpeedKmh;
  final double? avgSpeedKmh;
  final double? maxGForce;
  final double? maxInclinationDegrees;
  final double? maxSoundDb;
  final DateTime createdAt;

  factory ScoreModel.fromJson(Map<String, dynamic> json) {
    return ScoreModel(
      id: json['id'] as int,
      routeId: json['route_id'] as int,
      userId: json['user_id'] as int,
      timeSeconds: (json['time_seconds'] as num).toDouble(),
      maxSpeedKmh: (json['max_speed_kmh'] as num?)?.toDouble(),
      avgSpeedKmh: (json['avg_speed_kmh'] as num?)?.toDouble(),
      maxGForce: (json['max_g_force'] as num?)?.toDouble(),
      maxInclinationDegrees:
          (json['max_inclination_degrees'] as num?)?.toDouble(),
      maxSoundDb: (json['max_sound_db'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class SensorSample {
  const SensorSample({
    required this.timestampOffsetMs,
    this.accelX,
    this.accelY,
    this.accelZ,
    this.gyroX,
    this.gyroY,
    this.gyroZ,
    this.orientationAzimuth,
    this.orientationPitch,
    this.orientationRoll,
    this.speedKmh,
    this.gForce,
    this.inclinationDegrees,
    this.soundDb,
    this.nearbyDevices,
    this.latitude,
    this.longitude,
    this.altitude,
  });

  final int timestampOffsetMs;
  final double? accelX;
  final double? accelY;
  final double? accelZ;
  final double? gyroX;
  final double? gyroY;
  final double? gyroZ;
  final double? orientationAzimuth;
  final double? orientationPitch;
  final double? orientationRoll;
  final double? speedKmh;
  final double? gForce;
  final double? inclinationDegrees;
  final double? soundDb;
  final int? nearbyDevices;
  final double? latitude;
  final double? longitude;
  final double? altitude;

  Map<String, dynamic> toJson() => {
        'timestamp_offset_ms': timestampOffsetMs,
        'accel_x': accelX,
        'accel_y': accelY,
        'accel_z': accelZ,
        'gyro_x': gyroX,
        'gyro_y': gyroY,
        'gyro_z': gyroZ,
        'orientation_azimuth': orientationAzimuth,
        'orientation_pitch': orientationPitch,
        'orientation_roll': orientationRoll,
        'speed_kmh': speedKmh,
        'g_force': gForce,
        'inclination_degrees': inclinationDegrees,
        'sound_db': soundDb,
        'nearby_devices': nearbyDevices,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
      };

  factory SensorSample.fromJson(Map<String, dynamic> json) {
    return SensorSample(
      timestampOffsetMs: json['timestamp_offset_ms'] as int,
      accelX: (json['accel_x'] as num?)?.toDouble(),
      accelY: (json['accel_y'] as num?)?.toDouble(),
      accelZ: (json['accel_z'] as num?)?.toDouble(),
      gyroX: (json['gyro_x'] as num?)?.toDouble(),
      gyroY: (json['gyro_y'] as num?)?.toDouble(),
      gyroZ: (json['gyro_z'] as num?)?.toDouble(),
      orientationAzimuth:
          (json['orientation_azimuth'] as num?)?.toDouble(),
      orientationPitch: (json['orientation_pitch'] as num?)?.toDouble(),
      orientationRoll: (json['orientation_roll'] as num?)?.toDouble(),
      speedKmh: (json['speed_kmh'] as num?)?.toDouble(),
      gForce: (json['g_force'] as num?)?.toDouble(),
      inclinationDegrees:
          (json['inclination_degrees'] as num?)?.toDouble(),
      soundDb: (json['sound_db'] as num?)?.toDouble(),
      nearbyDevices: json['nearby_devices'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
    );
  }
}

class RunMetrics {
  const RunMetrics({
    required this.distanceMeters,
    required this.currentSpeedKmh,
    required this.maxSpeedKmh,
    required this.avgSpeedKmh,
    required this.maxGForce,
    required this.maxInclinationDegrees,
    required this.maxSoundDb,
    required this.accuracyMeters,
    required this.gpsQuality,
  });

  final double distanceMeters;
  final double currentSpeedKmh;
  final double maxSpeedKmh;
  final double avgSpeedKmh;
  final double maxGForce;
  final double maxInclinationDegrees;
  final double? maxSoundDb;
  final double accuracyMeters;
  final GpsQuality gpsQuality;

  const RunMetrics.initial()
      : distanceMeters = 0,
        currentSpeedKmh = 0,
        maxSpeedKmh = 0,
        avgSpeedKmh = 0,
        maxGForce = 0,
        maxInclinationDegrees = 0,
        maxSoundDb = null,
        accuracyMeters = 0,
        gpsQuality = GpsQuality.good;

  RunMetrics copyWith({
    double? distanceMeters,
    double? currentSpeedKmh,
    double? maxSpeedKmh,
    double? avgSpeedKmh,
    double? maxGForce,
    double? maxInclinationDegrees,
    double? maxSoundDb,
    double? accuracyMeters,
    GpsQuality? gpsQuality,
  }) {
    return RunMetrics(
      distanceMeters: distanceMeters ?? this.distanceMeters,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      maxGForce: maxGForce ?? this.maxGForce,
      maxInclinationDegrees:
          maxInclinationDegrees ?? this.maxInclinationDegrees,
      maxSoundDb: maxSoundDb ?? this.maxSoundDb,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      gpsQuality: gpsQuality ?? this.gpsQuality,
    );
  }
}

class RunSummary {
  const RunSummary({
    required this.routeName,
    required this.routeId,
    required this.freeMode,
    required this.elapsed,
    required this.metrics,
    required this.completedAt,
  });

  final String routeName;
  final int? routeId;
  final bool freeMode;
  final Duration elapsed;
  final RunMetrics metrics;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => {
        'routeName': routeName,
        'routeId': routeId,
        'freeMode': freeMode,
        'elapsedMs': elapsed.inMilliseconds,
        'metrics': {
          'distanceMeters': metrics.distanceMeters,
          'currentSpeedKmh': metrics.currentSpeedKmh,
          'maxSpeedKmh': metrics.maxSpeedKmh,
          'avgSpeedKmh': metrics.avgSpeedKmh,
          'maxGForce': metrics.maxGForce,
          'maxInclinationDegrees': metrics.maxInclinationDegrees,
          'maxSoundDb': metrics.maxSoundDb,
          'accuracyMeters': metrics.accuracyMeters,
          'gpsQuality': metrics.gpsQuality.name,
        },
        'completedAt': completedAt.toIso8601String(),
      };

  factory RunSummary.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] as Map<String, dynamic>? ?? const {};
    return RunSummary(
      routeName: json['routeName'] as String? ?? 'Session',
      routeId: json['routeId'] as int?,
      freeMode: json['freeMode'] as bool? ?? false,
      elapsed: Duration(milliseconds: json['elapsedMs'] as int? ?? 0),
      metrics: RunMetrics(
        distanceMeters: (metrics['distanceMeters'] as num?)?.toDouble() ?? 0,
        currentSpeedKmh:
            (metrics['currentSpeedKmh'] as num?)?.toDouble() ?? 0,
        maxSpeedKmh: (metrics['maxSpeedKmh'] as num?)?.toDouble() ?? 0,
        avgSpeedKmh: (metrics['avgSpeedKmh'] as num?)?.toDouble() ?? 0,
        maxGForce: (metrics['maxGForce'] as num?)?.toDouble() ?? 0,
        maxInclinationDegrees:
            (metrics['maxInclinationDegrees'] as num?)?.toDouble() ?? 0,
        maxSoundDb: (metrics['maxSoundDb'] as num?)?.toDouble(),
        accuracyMeters: (metrics['accuracyMeters'] as num?)?.toDouble() ?? 0,
        gpsQuality: GpsQuality.values.firstWhere(
          (quality) => quality.name == metrics['gpsQuality'],
          orElse: () => GpsQuality.good,
        ),
      ),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class PendingRunUpload {
  const PendingRunUpload({
    required this.routeId,
    required this.routeDraft,
    required this.recordedPath,
    required this.elapsed,
    required this.metrics,
    required this.samples,
    required this.createdAt,
  });

  final int? routeId;
  final RouteDraft? routeDraft;
  final List<RoutePathPoint> recordedPath;
  final Duration elapsed;
  final RunMetrics metrics;
  final List<SensorSample> samples;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'routeId': routeId,
        'routeDraft': routeDraft?.toJson(),
        'recordedPath':
            recordedPath.map((point) => point.toJson()).toList(growable: false),
        'elapsedMs': elapsed.inMilliseconds,
        'metrics': {
          'distanceMeters': metrics.distanceMeters,
          'currentSpeedKmh': metrics.currentSpeedKmh,
          'maxSpeedKmh': metrics.maxSpeedKmh,
          'avgSpeedKmh': metrics.avgSpeedKmh,
          'maxGForce': metrics.maxGForce,
          'maxInclinationDegrees': metrics.maxInclinationDegrees,
          'maxSoundDb': metrics.maxSoundDb,
          'accuracyMeters': metrics.accuracyMeters,
          'gpsQuality': metrics.gpsQuality.name,
        },
        'samples': samples.map((sample) => sample.toJson()).toList(growable: false),
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingRunUpload.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] as Map<String, dynamic>? ?? const {};
    return PendingRunUpload(
      routeId: json['routeId'] as int?,
      routeDraft: json['routeDraft'] == null
          ? null
          : RouteDraft.fromJson(json['routeDraft'] as Map<String, dynamic>),
      recordedPath: (json['recordedPath'] as List<dynamic>? ?? const [])
          .map(
            (point) => RoutePathPoint.fromJson(point as Map<String, dynamic>),
          )
          .toList(growable: false),
      elapsed: Duration(milliseconds: json['elapsedMs'] as int? ?? 0),
      metrics: RunMetrics(
        distanceMeters: (metrics['distanceMeters'] as num?)?.toDouble() ?? 0,
        currentSpeedKmh:
            (metrics['currentSpeedKmh'] as num?)?.toDouble() ?? 0,
        maxSpeedKmh: (metrics['maxSpeedKmh'] as num?)?.toDouble() ?? 0,
        avgSpeedKmh: (metrics['avgSpeedKmh'] as num?)?.toDouble() ?? 0,
        maxGForce: (metrics['maxGForce'] as num?)?.toDouble() ?? 0,
        maxInclinationDegrees:
            (metrics['maxInclinationDegrees'] as num?)?.toDouble() ?? 0,
        maxSoundDb: (metrics['maxSoundDb'] as num?)?.toDouble(),
        accuracyMeters: (metrics['accuracyMeters'] as num?)?.toDouble() ?? 0,
        gpsQuality: GpsQuality.values.firstWhere(
          (quality) => quality.name == metrics['gpsQuality'],
          orElse: () => GpsQuality.good,
        ),
      ),
      samples: (json['samples'] as List<dynamic>? ?? const [])
          .map((sample) => SensorSample.fromJson(sample as Map<String, dynamic>))
          .toList(growable: false),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String encode() => jsonEncode(toJson());

  factory PendingRunUpload.decode(String raw) =>
      PendingRunUpload.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

class RunSessionState {
  const RunSessionState({
    required this.phase,
    required this.elapsed,
    required this.metrics,
    required this.path,
    required this.samplesCollected,
    required this.freeMode,
    this.route,
    this.routeDraft,
    this.lastSummary,
    this.lastError,
    this.pendingUploads = 0,
    this.lastScore,
  });

  final RunSessionPhase phase;
  final Duration elapsed;
  final RunMetrics metrics;
  final List<RoutePathPoint> path;
  final int samplesCollected;
  final bool freeMode;
  final RouteModel? route;
  final RouteDraft? routeDraft;
  final RunSummary? lastSummary;
  final String? lastError;
  final int pendingUploads;
  final ScoreModel? lastScore;

  bool get isRunning => phase == RunSessionPhase.running;

  const RunSessionState.initial()
      : phase = RunSessionPhase.idle,
        elapsed = Duration.zero,
        metrics = const RunMetrics.initial(),
        path = const [],
        samplesCollected = 0,
        freeMode = false,
        route = null,
        routeDraft = null,
        lastSummary = null,
        lastError = null,
        pendingUploads = 0,
        lastScore = null;

  RunSessionState copyWith({
    RunSessionPhase? phase,
    Duration? elapsed,
    RunMetrics? metrics,
    List<RoutePathPoint>? path,
    int? samplesCollected,
    bool? freeMode,
    RouteModel? route,
    RouteDraft? routeDraft,
    RunSummary? lastSummary,
    String? lastError,
    int? pendingUploads,
    ScoreModel? lastScore,
    bool clearRoute = false,
    bool clearDraft = false,
    bool clearSummary = false,
    bool clearError = false,
  }) {
    return RunSessionState(
      phase: phase ?? this.phase,
      elapsed: elapsed ?? this.elapsed,
      metrics: metrics ?? this.metrics,
      path: path ?? this.path,
      samplesCollected: samplesCollected ?? this.samplesCollected,
      freeMode: freeMode ?? this.freeMode,
      route: clearRoute ? null : route ?? this.route,
      routeDraft: clearDraft ? null : routeDraft ?? this.routeDraft,
      lastSummary: clearSummary ? null : lastSummary ?? this.lastSummary,
      lastError: clearError ? null : lastError ?? this.lastError,
      pendingUploads: pendingUploads ?? this.pendingUploads,
      lastScore: lastScore ?? this.lastScore,
    );
  }
}
