import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/services.dart' show rootBundle;


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const Duration _ignoreDuration = Duration(milliseconds: 20);

  Timer? _timer;
  UserAccelerometerEvent? _userAccelerometerEvent;

  DateTime? _userAccelerometerUpdateTime;

  int? _userAccelerometerLastInterval;

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  final Stopwatch _stopwatch = Stopwatch();

  Duration sensorInterval = SensorInterval.normalInterval;
  Flutter3DController controller = Flutter3DController();

  String axis_right = "0.0";
  String axis_left = "0.0";
  String axis_front = "0.0";
  String axis_back = "0.0";

  String _formatTime(int ms) {
    int hundreds = (ms / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();

    String mnStr = (minutes % 60).toString().padLeft(2, '0');
    String sStr = (seconds % 60).toString().padLeft(2, '0');
    String hStr = (hundreds % 100).toString().padLeft(2, '0');

    return "$mnStr:$sStr:$hStr";
  }

  void _startStopwatch() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(
          const Duration(milliseconds: 30), (timer) {
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  // afficher l'accélaration avant, arriere, et sur les cotés comme ça pas d'affichage de négatif
  void setup2dAcceleration() {

    // si le x qui représente les cotés
    // négatif alors gauche et positif droite
    if (_userAccelerometerEvent!.x < 0.0) {
      axis_left = _userAccelerometerEvent?.x.toStringAsFixed(1) ?? '0.00';
    } else {
      axis_right = _userAccelerometerEvent?.x.toStringAsFixed(1) ?? '0.00';
    }
    if (_userAccelerometerEvent!.z < 0.0) {
      axis_back = _userAccelerometerEvent?.z.toStringAsFixed(1) ?? '0.00';
    } else {
      axis_front = _userAccelerometerEvent?.z.toStringAsFixed(1) ?? '0.00';
    }
  }


  @override
  void initState() {
    super.initState();
    _streamSubscriptions.add(
      userAccelerometerEventStream(samplingPeriod: sensorInterval).listen(
            (UserAccelerometerEvent event) {
          final now = event.timestamp;
          setState(() {
            _userAccelerometerEvent = event;
            if (_userAccelerometerUpdateTime != null) {
              final interval = now.difference(_userAccelerometerUpdateTime!);
              if (interval > _ignoreDuration) {
                _userAccelerometerLastInterval = interval.inMilliseconds;
              }
            }
          });
          _userAccelerometerUpdateTime = now;
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
              });
        },
        cancelOnError: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          // chrono
          Expanded(
              flex: 2,
              child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              _formatTime(_stopwatch.elapsedMilliseconds),
                              style: const TextStyle(
                                fontSize: 60.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              )
                          ),
                        ],
                      ),
                      const SizedBox(height: 30,),
                      // acceleraometre
                      Text(
                        'X: ${_userAccelerometerEvent?.x.toStringAsFixed(1) ?? '?'}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        'Z: ${_userAccelerometerEvent?.z.toStringAsFixed(1) ?? '?'}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 10,),
                      // start and stop button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _stopwatch.isRunning ? null : _startStopwatch,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade100),
                            child: const Text('Start'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _stopwatch.isRunning ? _stopStopwatch : null,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade100),
                            child: const Text('Stop'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                              onPressed: _resetStopwatch,
                              child: const Text('Reset'))
                        ],
                      )
                    ],
                  )
              )
          ),
          // modele 3d
          Expanded(
              flex: 3,
              child: Flutter3DViewer(
                enableTouch: true,
                controller: controller,
                src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
                onProgress: (double progressValue) {
                  debugPrint('chargement du modele: $progressValue');
                },
                onError: (String error) {
                  debugPrint('erreur: $error');
                },
              )
          ),
        ]
      )
    );
  }
}