import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';


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
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_userAccelerometerEvent?.x.toStringAsFixed(1) ?? '?'),
            Text(_userAccelerometerEvent?.y.toStringAsFixed(1) ?? '?'),
            Text(_userAccelerometerEvent?.z.toStringAsFixed(1) ?? '?'),
            Text('${_userAccelerometerLastInterval?.toString() ?? '?'} ms'),
            Text(
              _formatTime(_stopwatch.elapsedMilliseconds),
              style: const TextStyle(
                fontSize: 60.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 30,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _stopwatch.isRunning ? null : _startStopwatch,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade100),
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: _stopwatch.isRunning ? _stopStopwatch : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100),
                  child: const Text('Stop'),
                ),
                const SizedBox(width: 10,),
                ElevatedButton(
                    onPressed: _resetStopwatch, child: const Text('Reset'))
              ],
            )
          ],
        ),
      ),
    );
  }
}