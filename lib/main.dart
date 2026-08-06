import 'package:driver_hub/desktop_shell/window_bootstrap_stub.dart'
    if (dart.library.io) 'package:driver_hub/desktop_shell/window_bootstrap.dart'
    as window_bootstrap;
import 'package:driver_hub/layer3_ui/screens/devices_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (_isDesktop) {
    // why: native handle may be null until the first frame attaches the window.
    window_bootstrap.configureDesktopWindow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      window_bootstrap.configureDesktopWindow();
    });
  }
  runApp(const DriverHubApp());
}

bool get _isDesktop {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      return true;
    default:
      return false;
  }
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
