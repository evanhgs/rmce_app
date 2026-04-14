import 'package:latlong2/latlong.dart';

import '../../services/gps_service.dart';
import '../routes/route_models.dart';
import 'run_models.dart';

class RunTrackingSnapshot {
  const RunTrackingSnapshot({
    required this.path,
    required this.metrics,
  });

  final List<RoutePathPoint> path;
  final RunMetrics metrics;
}

class RunTrackingService {
  final Distance _distance = const Distance();

  final List<RoutePathPoint> _acceptedPoints = [];
  RunMetrics _metrics = const RunMetrics.initial();
  DateTime? _lastAcceptedAt;

  void reset() {
    _acceptedPoints.clear();
    _metrics = const RunMetrics.initial();
    _lastAcceptedAt = null;
  }

  RunTrackingSnapshot applyGpsSample(
    SpeedData data,
    Duration elapsed,
  ) {
    final point = RoutePathPoint(
      latitude: data.latitude,
      longitude: data.longitude,
    );

    final quality = _qualityForAccuracy(data.accuracy);
    if (_shouldAccept(point, data.accuracy, data.timestamp)) {
      if (_acceptedPoints.isNotEmpty) {
        _metrics = _metrics.copyWith(
          distanceMeters: _metrics.distanceMeters +
              _distance(_acceptedPoints.last.latLng, point.latLng),
        );
      }
      _acceptedPoints.add(point);
      _lastAcceptedAt = data.timestamp;
    }

    final elapsedHours = elapsed.inMilliseconds <= 0
        ? 0.0
        : elapsed.inMilliseconds / Duration.millisecondsPerHour;
    final avgSpeed = elapsedHours == 0
        ? 0.0
        : (_metrics.distanceMeters / 1000) / elapsedHours;

    _metrics = _metrics.copyWith(
      currentSpeedKmh: data.speed,
      maxSpeedKmh: data.speed > _metrics.maxSpeedKmh
          ? data.speed
          : _metrics.maxSpeedKmh,
      avgSpeedKmh: avgSpeed,
      accuracyMeters: data.accuracy,
      gpsQuality: quality,
    );

    return RunTrackingSnapshot(
      path: List<RoutePathPoint>.unmodifiable(_acceptedPoints),
      metrics: _metrics,
    );
  }

  RunTrackingSnapshot applySensorStats({
    required double gForce,
    required double inclinationDegrees,
    double? soundDb,
  }) {
    _metrics = _metrics.copyWith(
      maxGForce: gForce > _metrics.maxGForce ? gForce : _metrics.maxGForce,
      maxInclinationDegrees: inclinationDegrees > _metrics.maxInclinationDegrees
          ? inclinationDegrees
          : _metrics.maxInclinationDegrees,
      maxSoundDb: soundDb == null
          ? _metrics.maxSoundDb
          : (_metrics.maxSoundDb == null || soundDb > _metrics.maxSoundDb!
              ? soundDb
              : _metrics.maxSoundDb),
    );

    return RunTrackingSnapshot(
      path: List<RoutePathPoint>.unmodifiable(_acceptedPoints),
      metrics: _metrics,
    );
  }

  bool _shouldAccept(
    RoutePathPoint point,
    double accuracyMeters,
    DateTime timestamp,
  ) {
    if (accuracyMeters > 35 && _acceptedPoints.isNotEmpty) {
      return false;
    }

    if (_acceptedPoints.isEmpty) {
      return true;
    }

    final lastPoint = _acceptedPoints.last;
    final distanceMeters = _distance(lastPoint.latLng, point.latLng);
    final deltaMs = timestamp.difference(_lastAcceptedAt ?? timestamp).inMilliseconds;

    if (distanceMeters < 1.5) {
      return false;
    }

    if (deltaMs > 0) {
      final speedMps = distanceMeters / (deltaMs / 1000);
      if (speedMps > 55) {
        return false;
      }
    }

    return true;
  }

  GpsQuality _qualityForAccuracy(double accuracyMeters) {
    if (accuracyMeters <= 5) {
      return GpsQuality.excellent;
    }
    if (accuracyMeters <= 10) {
      return GpsQuality.good;
    }
    if (accuracyMeters <= 20) {
      return GpsQuality.degraded;
    }
    return GpsQuality.poor;
  }
}
