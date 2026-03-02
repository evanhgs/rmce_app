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
          LatLng newPosition = LatLng(speedData.latitude, speedData.longitude);

          // Calculer la direction (heading) basée sur le mouvement précédent
          if (_previousPosition != null) {
            final distance = Distance().as(LengthUnit.Meter, _previousPosition!, newPosition);
            if (distance > 0.001) { // Éviter les calculs avec des positions identiques
              final latDiff = newPosition.latitude - _previousPosition!.latitude;
              final lngDiff = newPosition.longitude - _previousPosition!.longitude;
              _heading = math.atan2(lngDiff, latDiff) * (180 / math.pi);
            }
          }
          _previousPosition = newPosition;

          if (_userPosition == null) {
            _userPosition = newPosition;
          } else {
            _userPosition = newPosition;
          }

          // Auto-center la première fois
          if (_isFirstUpdate && _userPosition != null) {
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
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
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
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(48.8566, 2.3522),
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 19.0,
            ),
            children: [
              TileLayer(
                // Utiliser CartoDB qui est plus stable et maintenu
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'rmce_app.evanhgs.fr',
                subdomains: const ['a', 'b', 'c', 'd'],
                maxZoom: 19,
                minZoom: 1,
                additionalOptions: {
                  'attribution':
                    '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
                },
              ),
              // Marqueur utilisateur avec triangle pointant la direction
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
                            // Triangle pointant vers le haut (direction)
                            CustomPaint(
                              size: const Size(50, 50),
                              painter: TrianglePainter(),
                            ),
                            // Cercle au centre pour la localisation précise
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade400.withOpacity(0.6),
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

          // Panneau de vitesse
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 140,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade700.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade700.withOpacity(0.2),
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

          // Boutons de contrôle
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              children: [
                // Bouton Zoom In
                GestureDetector(
                  onTap: _zoomIn,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade800,
                      border: Border.all(
                        color: Colors.grey.shade700,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Bouton Zoom Out
                GestureDetector(
                  onTap: _zoomOut,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade800,
                      border: Border.all(
                        color: Colors.grey.shade700,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Bouton Center
                GestureDetector(
                  onTap: _centerOnLocation,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.shade700,
                      border: Border.all(
                        color: Colors.blue.shade600,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade700.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 24,
                    ),
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

/// Custom painter pour dessiner un triangle pointant vers le haut (style Google Maps)
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade400
      ..style = PaintingStyle.fill;

    final path = ui.Path();
    // Pointe vers le haut
    path.moveTo(size.width / 2, 0); // Sommet en haut
    path.lineTo(size.width, size.height); // Coin bas droit
    path.lineTo(0, size.height); // Coin bas gauche
    path.close();

    canvas.drawPath(path, paint);

    // Bordure blanche pour meilleure visibilité
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


