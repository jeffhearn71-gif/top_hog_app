import 'package:flutter/material.dart';

import 'presentation/screens/game_test_screen.dart';

void main() {
  runApp(const TopHogApp());
}

class TopHogApp extends StatelessWidget {
  const TopHogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Top Hog',
      theme: ThemeData(primarySwatch: Colors.pink),
      home: const GameTestScreen(),
    );
  }
}
