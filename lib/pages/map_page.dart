import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';


class MapPage extends StatefulWidget {
  final String title;

  const MapPage({super.key, required this.title});


  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  final MapController _mapController = MapController();
  LatLng _center = const LatLng(48.8566, 2.3522);
  LatLng? _userPosition;
  bool _loading = false;
  final _stopwatch = Stopwatch();

  Future<void> _animateToLocation(LatLng location) async {
    _mapController.move(location, 16.0);
  }

  Future<void> _goToMyLocation() async {
    setState(() => _loading = true);
    _stopwatch.reset();
    _stopwatch.start();

    try {
      while (_stopwatch.elapsedMilliseconds <= 10000) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.deniedForever) {
          if (mounted) {
            setState(() => _loading = false);
          }
          break;
        }

        final pos = await Geolocator.getCurrentPosition();
        final latLng = LatLng(pos.latitude, pos.longitude);

        if (mounted) {
          setState(() {
            _userPosition = latLng;
            _center = latLng;
            _loading = false;
          });
          await _animateToLocation(latLng);
        }
        break;
      }
    } finally {
      _stopwatch.stop();
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title),),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: 13.0,
          minZoom: 3.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'evanhgs.fr',
          ),
          if (_userPosition != null)
            MarkerLayer(markers: [
              Marker(
                  point: _userPosition!,
                  width: 60,
                  height: 60,
                  child: const Icon(Icons.my_location, color: Colors.blue, size: 40)
              )
            ])
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _goToMyLocation,
        child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.my_location),
      ),
    );
  }
}