import 'package:driver_hub/desktop_shell/window_bootstrap_stub.dart'
    if (dart.library.io) 'package:driver_hub/desktop_shell/window_bootstrap.dart'
    as window_bootstrap;
import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer3_ui/screens/devices_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class DriverHubApp extends StatefulWidget {
  const DriverHubApp({super.key});

  @override
  State<DriverHubApp> createState() => _DriverHubAppState();
}

class _DriverHubAppState extends State<DriverHubApp> {
  /// Hot reload (debug only): clear the L2 capability cache and evict the
  /// bundled catalog assets so catalog JSON edits are picked up without a full
  /// restart. Hot reload rebuilds the whole tree from the root, so refreshed
  /// lookups re-render capability-gated UI.
  @override
  void reassemble() {
    super.reassemble();
    if (kDebugMode) {
      DeviceCapabilityStore.debugReset();
      rootBundle.evict('assets/catalog/mouse/m7x.json');
      rootBundle.evict('assets/catalog/mouse/m7xse.json');
      rootBundle.evict('assets/catalog/mouse/m7x_pro.json');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'driver_hub',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const DevicesScreen(),
    );
  }
}
