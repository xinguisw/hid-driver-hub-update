import 'package:flutter/material.dart';
import 'package:driver_hub/layer3_ui/widgets/app_top_bar.dart';
import 'package:driver_hub/layer3_ui/screens/devices_screen.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.scope});

  final DeviceScope scope;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(scope: scope),
      body: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(builder: (_) => DevicesScreen(scope: scope));
        },
      ),
    );
  }
}
