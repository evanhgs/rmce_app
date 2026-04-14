import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'app_theme.dart';

class RmceApp extends StatelessWidget {
  const RmceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RMCE',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}
