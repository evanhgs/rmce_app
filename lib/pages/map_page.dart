import 'package:flutter/material.dart';

class MapPage extends StatefulWidget {
  final String title;

  const MapPage({super.key, required this.title});


  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  double? latitude;
  double? longitude;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Text('Position: $latitude, $longitude'),
      ),
    );
  }
}