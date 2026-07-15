import 'package:driver_hub/layer3_ui/models/discovered_card_state.dart';
import 'package:driver_hub/layer1_discovery/device_connection_manager.dart';
import 'package:driver_hub/layer3_ui/widgets/device_card_grid.dart';
import 'package:driver_hub/layer3_ui/widgets/empty_device_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Home screen: one [DeviceCard] per verified device.
///
/// Pure composition (CDD): owns no lifecycle, no HID, no scanner. It reads the
/// [DeviceScope] and composes [DeviceCardGrid] / [EmptyDeviceState]. All
/// hardware concern lives in [DeviceScope] (L1); this is L3.
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  late final DeviceScope _scope;

  @override
  void initState() {
    super.initState();
    _scope = DeviceScope();
    _scope.start();
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('driver_hub')),
      body: Column(
        children: [
          if (kIsWeb) _addDeviceBar,
          Expanded(
            child: ValueListenableBuilder<List<DiscoveredCardState>>(
              valueListenable: _scope.cards,
              builder: (context, cards, _) {
                if (cards.isEmpty) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _scope.busy,
                    builder: (context, busy, _) =>
                        EmptyDeviceState(busy: busy),
                  );
                }
                return DeviceCardGrid(cards: cards);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Always-visible on web so a second device can be added. Disabled while a
  /// scan is in flight.
  Widget get _addDeviceBar {
    return ValueListenableBuilder<bool>(
      valueListenable: _scope.busy,
      builder: (context, busy, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: busy ? null : _scope.addDevice,
          icon: const Icon(Icons.add),
          label: Text(busy ? 'Working…' : 'Add device'),
        ),
      ),
    );
  }
}
