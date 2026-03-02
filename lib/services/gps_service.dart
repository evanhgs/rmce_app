import 'dart:async';
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

  factory GPSService() {
    return _instance;
  }

  GPSService._internal();

  StreamSubscription<Position>? _positionStream;
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _latitude = 0.0;
  double _longitude = 0.0;
  double _altitude = 0.0;
  double _accuracy = 0.0;
  bool _isInitialized = false;

  // StreamController pour les updates de vitesse
  final _speedController = StreamController<SpeedData>.broadcast();

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
    if (_isInitialized) return;

    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si le service de localisation est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Service de localisation désactivé');
      return;
    }

    // Vérifier les permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permission de localisation refusée');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Permission de localisation refusée définitivement');
      return;
    }

    _isInitialized = true;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      // Conversion m/s en km/h
      _currentSpeed = (position.speed * 3.6).clamp(0, 400);
      _latitude = position.latitude;
      _longitude = position.longitude;
      _altitude = position.altitude;
      _accuracy = position.accuracy;

      if (_currentSpeed > _maxSpeed) {
        _maxSpeed = _currentSpeed;
      }

      // Émettre les données
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

