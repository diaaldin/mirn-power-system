import 'package:flutter/material.dart';

void main() {
  runApp(const MirnPowerApp());
}

class MirnPowerApp extends StatelessWidget {
  const MirnPowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M.I.R.N POWER',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC5A059)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('M.I.R.N POWER Management System'),
        ),
      ),
    );
  }
}
