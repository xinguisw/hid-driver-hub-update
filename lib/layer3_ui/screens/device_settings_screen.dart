import 'package:driver_hub/layer3_ui/models/discovered_card_state.dart';
import 'package:driver_hub/layer1_discovery/device_session.dart';
import 'package:driver_hub/layer1_discovery/device_connection_manager.dart';
import 'package:flutter/material.dart';

/// Device settings page — opened from a mouse card tap.
///
/// On open: runs onboard config GETs for this mouse (not at app start / card load).
/// UI body still empty; results go to console for now.
class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({
    super.key,
    required this.card,
    required this.scope,
  });

  /// Card of the device the user selected.
  final DiscoveredCardState card;

  /// Owns live sessions; used only to resolve session + run config queries.
  final DeviceScope scope;

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // After first frame so navigation is done before HID traffic.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOnboardConfig());
  }

  Future<void> _loadOnboardConfig() async {
    final DeviceSession? session = widget.scope.sessionForCard(widget.card);
    if (session == null || !session.isAlive) {
      debugPrint('[settings] ${widget.card.displayName}: no live session');
      return;
    }
    debugPrint('[settings] ${widget.card.displayName}: loading onboard config…');
    await widget.scope.queryOnboardConfig(session);
    debugPrint('[settings] ${widget.card.displayName}: onboard config done');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card.displayName),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
