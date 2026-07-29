import 'package:driver_hub/layer3_ui/screens/hub_landing_screen.dart';
import 'package:driver_hub/layer3_ui/widgets/device_card_grid.dart';
import 'package:driver_hub/layer3_ui/widgets/empty_device_state.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Home screen: one [DeviceCard] per verified device.
///
/// L3 only: reads L4 [DeviceScope] cards. Card tap → [HubLandingScreen].
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
                return DeviceCardGrid(
                  cards: cards,
                  onCardTap: _openHubLanding,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openHubLanding(DiscoveredCardState card) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HubLandingScreen(card: card, scope: _scope),
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
