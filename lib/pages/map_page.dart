import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/gps_service.dart';

class MapPage extends StatefulWidget {
  final String title;

  const MapPage({super.key, required this.title});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final GPSService _gpsService = GPSService();

  LatLng? _userPosition;
  StreamSubscription<SpeedData>? _speedSubscription;
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  bool _isFirstUpdate = true;
  double _heading = 0.0;
  LatLng? _previousPosition;

  @override
  void initState() {
    super.initState();
    _gpsService.init();

    _speedSubscription = _gpsService.speedStream.listen((speedData) {
      if (mounted) {
        setState(() {
          _currentSpeed = speedData.speed;
          _maxSpeed = speedData.maxSpeed;
          final newPosition = LatLng(speedData.latitude, speedData.longitude);

          if (_previousPosition != null) {
            final distance =
                Distance().as(LengthUnit.Meter, _previousPosition!, newPosition);
            if (distance > 0.001) {
              final latDiff = newPosition.latitude - _previousPosition!.latitude;
              final lngDiff = newPosition.longitude - _previousPosition!.longitude;
              _heading = math.atan2(lngDiff, latDiff) * (180 / math.pi);
            }
          }
          _previousPosition = newPosition;
          _userPosition = newPosition;

          if (_isFirstUpdate) {
            _mapController.move(_userPosition!, 18.0);
            _isFirstUpdate = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _speedSubscription?.cancel();
    super.dispose();
  }

  void _centerOnLocation() {
    if (_userPosition != null) {
      _mapController.move(_userPosition!, 18.0);
    }
  }

  void _zoomIn() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom + 1.0);
  }

  void _zoomOut() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom - 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(48.8566, 2.3522),
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 19.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'rmce_app.evanhgs.fr',
                subdomains: const ['a', 'b', 'c', 'd'],
                maxZoom: 19,
                additionalOptions: const {
                  'attribution':
                      '&copy; OpenStreetMap contributors &copy; CARTO',
                },
              ),
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userPosition!,
                      width: 50,
                      height: 50,
                      child: Transform.rotate(
                        angle: _heading * math.pi / 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(50, 50),
                              painter: TrianglePainter(),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade400
                                        .withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 140,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade700.withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade700.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'VITESSE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade500,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentSpeed.toInt().toString(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      color: Colors.blue.shade400,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'km/h',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: Colors.blue.shade300,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Max: ${_maxSpeed.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _zoomIn,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade800,
                      border: Border.all(color: Colors.grey.shade700, width: 1),
                    ),
                    child: Icon(Icons.add, color: Colors.grey.shade400, size: 28),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _zoomOut,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade800,
                      border: Border.all(color: Colors.grey.shade700, width: 1),
                    ),
                    child:
                        Icon(Icons.remove, color: Colors.grey.shade400, size: 28),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _centerOnLocation,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.shade700,
                      border:
                          Border.all(color: Colors.blue.shade600, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade700.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location,
                        color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue.shade400
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
