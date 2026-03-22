import 'package:flutter/material.dart';
import 'package:rmce_app/pages/friends_page.dart';
import 'package:rmce_app/pages/home_page.dart';
import 'package:rmce_app/pages/map_page.dart';
import 'package:rmce_app/pages/settings_page.dart';
import 'package:rmce_app/pages/top_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RMCE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade400,
          surface: const Color(0xFF111116),
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const RootPage(),
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

  static const _pages = [
    MyHomePage(title: 'Chrono'),
    MapPage(title: 'Map'),
    FriendsPage(title: 'Amis'),
    TopPage(title: 'Classement'),
    SettingsPage(title: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C10),
        border: Border(
          top: BorderSide(color: Colors.grey.shade900, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.speed_outlined, Icons.speed, 'Chrono'),
              _navItem(1, Icons.map_outlined, Icons.map, 'Map'),
              _navItem(
                  2, Icons.people_outline, Icons.people, 'Amis'),
              _navItem(3, Icons.leaderboard_outlined,
                  Icons.leaderboard, 'Classement'),
              _navItem(
                  4, Icons.person_outline, Icons.person, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.blue.shade700.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                selected ? activeIcon : icon,
                color: selected
                    ? Colors.blue.shade400
                    : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w500 : FontWeight.w400,
                color: selected
                    ? Colors.blue.shade400
                    : Colors.grey.shade600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
