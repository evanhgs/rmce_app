import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Racing mobile app',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100),
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: _stopwatch.isRunning ? _stopStopwatch : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
                  child: const Text('Stop'),
                ),
                const SizedBox(width: 10,),
                ElevatedButton(onPressed: _resetStopwatch, child: const Text('Reset'))
              ],
            )
          ],
        ),
      ),
    );
  }
}
