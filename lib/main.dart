import 'package:driver_hub/layer3_ui/screens/devices_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DriverHubApp());
}

class DriverHubApp extends StatelessWidget {
  const DriverHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'driver_hub',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const DevicesScreen(),
    );
  }
}
