import 'package:flutter/material.dart';
import 'package:rmce_app/pages/home_page.dart';
import 'package:rmce_app/pages/map_page.dart';

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
      home: RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MyHomePage(title: "Chrono"),
    MapPage(title: "Map")
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // indexedStack garde les pages en mémoire et évite que le chrono stop
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Chrono',),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map',),
        ],
      ),
    );
  }

}
