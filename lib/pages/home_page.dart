import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/gps_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer? _timer;

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  final Stopwatch _stopwatch = Stopwatch();

  final Duration sensorInterval = SensorInterval.uiInterval;
  final Flutter3DController controller = Flutter3DController();

  bool _isBtnVisible = false;

  String axis_right = "0.0";
  String axis_left = "0.0";
  String axis_front = "0.0";
  String axis_back = "0.0";

  DateTime? _lastAccelUpdate;

  final GPSService _gpsService = GPSService();
  StreamSubscription<SpeedData>? _speedSubscription;

  String _formatTime(int ms) {
    final hundreds = (ms / 10).truncate();
    final seconds = (hundreds / 100).truncate();
    final minutes = (seconds / 60).truncate();

    final mnStr = (minutes % 60).toString().padLeft(2, '0');
    final sStr = (seconds % 60).toString().padLeft(2, '0');
    final hStr = (hundreds % 100).toString().padLeft(2, '0');

    return "$mnStr:$sStr:$hStr";
  }

  void _startStopwatch() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        setState(() {});
      });
    }
  }

  void _stopStopwatch() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
      setState(() {});
    }
  }

  void _resetStopwatch() {
    _stopwatch.reset();
    if (!_stopwatch.isRunning) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    _gpsService.init();

    _speedSubscription = _gpsService.speedStream.listen((_) {
      setState(() {});
    });

    _streamSubscriptions.add(
      userAccelerometerEventStream(samplingPeriod: sensorInterval).listen(
        (UserAccelerometerEvent event) {
          final now = event.timestamp;

          if (_lastAccelUpdate == null ||
              now.difference(_lastAccelUpdate!).inMilliseconds >= 100) {
            setState(() {
              // X : gauche (-) / droite (+)
              if (event.x < 0) {
                axis_left = event.x.abs().toStringAsFixed(1);
                axis_right = "0.0";
              } else {
                axis_right = event.x.toStringAsFixed(1);
                axis_left = "0.0";
              }

              // Z : arrière (-) / face (+)
              if (event.z < 0) {
                axis_back = event.z.abs().toStringAsFixed(1);
                axis_front = "0.0";
              } else {
                axis_front = event.z.toStringAsFixed(1);
                axis_back = "0.0";
              }
            });
            _lastAccelUpdate = now;
          }
        },
        onError: (e) {
          showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                title: Text("Sensor Not Found"),
                content: Text(
                    "It seems that your device doesn't support User Accelerometer Sensor"),
              );
            },
          );
        },
        cancelOnError: true,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speedSubscription?.cancel();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
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
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.grey.shade900],
            ),
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.shade700.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Colors.grey.shade900, Colors.black],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade700.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _gpsService.currentSpeed.toInt().toString(),
                              style: TextStyle(
                                fontSize: 80,
                                fontWeight: FontWeight.w200,
                                color: Colors.blue.shade400,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'km/h',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: Colors.blue.shade300,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _formatTime(_stopwatch.elapsedMilliseconds),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                                color: Colors.white70,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (!_isBtnVisible) {
                          _startStopwatch();
                          setState(() => _isBtnVisible = true);
                        } else {
                          _stopStopwatch();
                          setState(() => _isBtnVisible = false);
                        }
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isBtnVisible ? Colors.red : Colors.green)
                                  .withValues(alpha: 0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          _isBtnVisible
                              ? 'assets/images/red_btn.png'
                              : 'assets/images/green_btn.png',
                          width: 70,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
                    GestureDetector(
                      onTap: () {
                        _resetStopwatch();
                        setState(() => _gpsService.resetMaxSpeed());
                      },
                      child: Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade800,
                          border: Border.all(
                            color: Colors.grey.shade700,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.restart_alt,
                          size: 28,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text(
                        'G-FORCES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAccelDisplay("FACE", axis_front, Colors.blue.shade400),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildAccelDisplay("G", axis_left, Colors.orange.shade400),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade800,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Flutter3DViewer(
                                    enableTouch: true,
                                    controller: controller,
                                    src: 'assets/models/lambo_car.glb',
                                    onProgress: (double progressValue) {
                                      debugPrint('Chargement: ${(progressValue * 100).toInt()}%');
                                    },
                                    onError: (String error) {
                                      debugPrint('Erreur 3D: $error');
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: _buildAccelDisplay("D", axis_right, Colors.orange.shade400),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAccelDisplay("ARRIÈRE", axis_back, Colors.red.shade400),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccelDisplay(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: color,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }
}
