import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SublyApp());
}

class SublyApp extends StatelessWidget {
  const SublyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
