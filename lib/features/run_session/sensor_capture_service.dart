import 'dart:async';
import 'dart:math' as math;

import 'package:noise_meter/noise_meter.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../services/gps_service.dart';
import 'run_models.dart';

class SensorCaptureSnapshot {
  const SensorCaptureSnapshot({
    required this.samples,
    required this.maxGForce,
    required this.maxInclinationDegrees,
    this.maxSoundDb,
  });

  final List<SensorSample> samples;
  final double maxGForce;
  final double maxInclinationDegrees;
  final double? maxSoundDb;
}

class SensorCaptureService {
  final List<SensorSample> _samples = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final NoiseMeter _noiseMeter = NoiseMeter();

  UserAccelerometerEvent? _lastAcceleration;
  GyroscopeEvent? _lastGyro;
  MagnetometerEvent? _lastMagnetometer;
  double? _lastSoundDb;
  DateTime? _startedAt;
  int _lastRecordedMs = -1;

  Future<void> start(Stream<SpeedData> gpsStream) async {
    _samples.clear();
    _startedAt = DateTime.now();
    _lastRecordedMs = -1;

    _subscriptions.add(
      userAccelerometerEventStream().listen(
        (event) {
          _lastAcceleration = event;
          _recordSnapshot();
        },
      ),
    );
    _subscriptions.add(
      gyroscopeEventStream().listen(
        (event) {
          _lastGyro = event;
          _recordSnapshot();
        },
      ),
    );
    _subscriptions.add(
      magnetometerEventStream().listen(
        (event) {
          _lastMagnetometer = event;
          _recordSnapshot();
        },
      ),
    );
    _subscriptions.add(
      gpsStream.listen(
        (_) => _recordSnapshot(),
      ),
    );
    _subscriptions.add(
      _noiseMeter.noise.listen(
        (reading) {
          _lastSoundDb = reading.meanDecibel;
          _recordSnapshot();
        },
        onError: (_) {},
      ),
    );
  }

  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  void reset() {
    _samples.clear();
    _lastAcceleration = null;
    _lastGyro = null;
    _lastMagnetometer = null;
    _lastSoundDb = null;
    _startedAt = null;
    _lastRecordedMs = -1;
  }

  SensorCaptureSnapshot get snapshot {
    var maxG = 0.0;
    var maxInclination = 0.0;
    double? maxSound;

    for (final sample in _samples) {
      maxG = math.max(maxG, sample.gForce ?? 0);
      maxInclination =
          math.max(maxInclination, sample.inclinationDegrees ?? 0);
      final sound = sample.soundDb;
      if (sound != null) {
        maxSound = maxSound == null ? sound : math.max(maxSound, sound);
      }
    }

    return SensorCaptureSnapshot(
      samples: List<SensorSample>.unmodifiable(_samples),
      maxGForce: maxG,
      maxInclinationDegrees: maxInclination,
      maxSoundDb: maxSound,
    );
  }

  void attachGpsSample(SpeedData data) {
    _recordSnapshot(currentGps: data);
  }

  void _recordSnapshot({SpeedData? currentGps}) {
    if (_startedAt == null) {
      return;
    }

    final offsetMs = DateTime.now().difference(_startedAt!).inMilliseconds;
    if (offsetMs == _lastRecordedMs || offsetMs % 250 > 40) {
      return;
    }
    _lastRecordedMs = offsetMs;

    final accel = _lastAcceleration;
    final gyro = _lastGyro;
    final magnetometer = _lastMagnetometer;

    final gForce = accel == null
        ? 0.0
        : math.sqrt(
            accel.x * accel.x + accel.y * accel.y + accel.z * accel.z,
          ) /
            9.80665;
    final pitch = accel == null
        ? 0.0
        : math.atan2(
            accel.y,
            math.sqrt(accel.x * accel.x + accel.z * accel.z),
          ) *
            180 /
            math.pi;
    final roll = accel == null
        ? 0.0
        : math.atan2(accel.x, accel.z) * 180 / math.pi;
    final azimuth = magnetometer == null
        ? null
        : (math.atan2(magnetometer.y, magnetometer.x) * 180 / math.pi + 360) %
            360;

    _samples.add(
      SensorSample(
        timestampOffsetMs: offsetMs,
        accelX: accel?.x,
        accelY: accel?.y,
        accelZ: accel?.z,
        gyroX: gyro?.x,
        gyroY: gyro?.y,
        gyroZ: gyro?.z,
        orientationAzimuth: azimuth,
        orientationPitch: pitch,
        orientationRoll: roll,
        speedKmh: currentGps?.speed,
        gForce: gForce,
        inclinationDegrees: pitch.abs(),
        soundDb: _lastSoundDb,
        nearbyDevices: null,
        latitude: currentGps?.latitude,
        longitude: currentGps?.longitude,
        altitude: currentGps?.altitude,
      ),
    );
  }
}
