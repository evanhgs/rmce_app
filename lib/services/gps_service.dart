import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class SpeedData {
  const SpeedData({
    required this.speed,
    required this.maxSpeed,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
  });

  final double speed;
  final double maxSpeed;
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;
}

class GPSService {
  static final GPSService _instance = GPSService._internal();

  factory GPSService() => _instance;
  GPSService._internal();

  StreamSubscription<Position>? _positionStream;
  final _speedController = StreamController<SpeedData>.broadcast();
  Future<void>? _initializationFuture;

  final List<double> _recentSpeeds = [];
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _latitude = 0.0;
  double _longitude = 0.0;
  double _altitude = 0.0;
  double _accuracy = 0.0;
  bool _isInitialized = false;

  Stream<SpeedData> get speedStream => _speedController.stream;
  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  double get latitude => _latitude;
  double get longitude => _longitude;
  double get altitude => _altitude;
  double get accuracy => _accuracy;
  bool get isInitialized => _isInitialized;
  bool get hasFix => _latitude != 0.0 || _longitude != 0.0;

  void resetMaxSpeed() {
    _maxSpeed = 0.0;
  }

  Future<void> init() async {
    if (_initializationFuture != null) {
      return _initializationFuture;
    }
    _initializationFuture = _initInternal();
    try {
      await _initializationFuture;
    } finally {
      _initializationFuture = null;
    }
  }

  Future<void> _initInternal() async {
    if (_isInitialized) {
      return;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      debugPrint('[GPS] Service de localisation désactivé');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[GPS] Permission refusée');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[GPS] Permission refusée définitivement');
      return;
    }

    await refreshCurrentPosition();

    _isInitialized = true;
    _positionStream = Geolocator.getPositionStream(
      locationSettings: _buildLocationSettings(),
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        debugPrint('[GPS] Erreur de stream position: $error');
      },
    );
  }

  LocationSettings _buildLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'RMCE suit votre parcours',
          notificationText:
              'La localisation reste active pour mesurer la session.',
          enableWakeLock: true,
        ),
      );
    }

    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }

  void _onPositionUpdate(Position position) {
    _latitude = position.latitude;
    _longitude = position.longitude;
    _altitude = position.altitude;
    _accuracy = position.accuracy;

    final rawSpeed = (position.speed * 3.6).clamp(0, 400).toDouble();
    _recentSpeeds.add(rawSpeed);
    if (_recentSpeeds.length > 5) {
      _recentSpeeds.removeAt(0);
    }

    final smoothSpeed =
        _recentSpeeds.reduce((left, right) => left + right) / _recentSpeeds.length;
    _currentSpeed = smoothSpeed;
    if (_currentSpeed > _maxSpeed) {
      _maxSpeed = _currentSpeed;
    }

    _speedController.add(
      _buildSpeedData(position.timestamp),
    );
  }

  SpeedData _buildSpeedData(DateTime timestamp) {
    return SpeedData(
      speed: _currentSpeed,
      maxSpeed: _maxSpeed,
      latitude: _latitude,
      longitude: _longitude,
      altitude: _altitude,
      accuracy: _accuracy,
      timestamp: timestamp,
    );
  }

  Future<SpeedData?> refreshCurrentPosition() async {
    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: _buildSingleShotLocationSettings(),
      );
      _onPositionUpdate(current);
      return _buildSpeedData(current.timestamp);
    } catch (error) {
      debugPrint('[GPS] getCurrentPosition a échoué: $error');
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _onPositionUpdate(lastKnown);
          return _buildSpeedData(lastKnown.timestamp);
        }
      } catch (lastKnownError) {
        debugPrint('[GPS] getLastKnownPosition a échoué: $lastKnownError');
      }
    }
    return null;
  }

  LocationSettings _buildSingleShotLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        timeLimit: const Duration(seconds: 10),
      );
    }

    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      timeLimit: Duration(seconds: 10),
    );
  }

  void dispose() {
    _positionStream?.cancel();
  }
}
