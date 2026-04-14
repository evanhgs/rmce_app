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

  void resetMaxSpeed() {
    _maxSpeed = 0.0;
  }

  Future<void> init() async {
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

    _isInitialized = true;
    _positionStream = Geolocator.getPositionStream(
      locationSettings: _buildLocationSettings(),
    ).listen(_onPositionUpdate);
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
      SpeedData(
        speed: _currentSpeed,
        maxSpeed: _maxSpeed,
        latitude: _latitude,
        longitude: _longitude,
        altitude: _altitude,
        accuracy: _accuracy,
        timestamp: position.timestamp,
      ),
    );
  }

  void dispose() {
    _positionStream?.cancel();
  }
}
