import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class SpeedData {
  final double speed; // km/h
  final double maxSpeed; // km/h
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;

  SpeedData({
    required this.speed,
    required this.maxSpeed,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
  });
}

class GPSService {
  static final GPSService _instance = GPSService._internal();

  factory GPSService() => _instance;
  GPSService._internal();

  StreamSubscription<Position>? _positionStream;
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _latitude = 0.0;
  double _longitude = 0.0;
  double _altitude = 0.0;
  double _accuracy = 0.0;
  bool _isInitialized = false;

  final _speedController = StreamController<SpeedData>.broadcast();

  Stream<SpeedData> get speedStream => _speedController.stream;
  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  double get latitude => _latitude;
  double get longitude => _longitude;
  double get altitude => _altitude;
  double get accuracy => _accuracy;
  bool get isInitialized => _isInitialized;

  void resetMaxSpeed() => _maxSpeed = 0.0;

  Future<void> init() async {
    if (_isInitialized) return;

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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      _currentSpeed = (position.speed * 3.6).clamp(0, 400);
      _latitude = position.latitude;
      _longitude = position.longitude;
      _altitude = position.altitude;
      _accuracy = position.accuracy;

      if (_currentSpeed > _maxSpeed) {
        _maxSpeed = _currentSpeed;
      }

      _speedController.add(SpeedData(
        speed: _currentSpeed,
        maxSpeed: _maxSpeed,
        latitude: _latitude,
        longitude: _longitude,
        altitude: _altitude,
        accuracy: _accuracy,
        timestamp: DateTime.now(),
      ));
    });
  }

  void dispose() {
    _positionStream?.cancel();
    _speedController.close();
  }
}
