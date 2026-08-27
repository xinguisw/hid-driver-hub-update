import 'package:driver_hub/layer3_ui/widgets/app_settings_panel.dart';
import 'package:driver_hub/layer3_ui/widgets/app_top_bar.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Full-page App Settings screen navigated from the global top bar.
///
/// Features a return/back button on the top-left corner of [AppTopBar].
class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({
    super.key,
    this.scope,
    this.lowBatteryThreshold,
    this.onLowBatteryThresholdChanged,
  });

  final DeviceScope? scope;
  final ValueListenable<int>? lowBatteryThreshold;
  final ValueChanged<int>? onLowBatteryThresholdChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final threshold = lowBatteryThreshold ??
        scope?.batteryLowThreshold ??
        ValueNotifier<int>(20);
    final onChanged = onLowBatteryThresholdChanged ??
        (val) => scope?.setLowBatteryThreshold(val);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppTopBar(
        showBackButton: false,
      ),
      body: AppSettingsPanel(
        lowBatteryThreshold: threshold,
        onLowBatteryThresholdChanged: onChanged,
      ),
    );
  }
}
