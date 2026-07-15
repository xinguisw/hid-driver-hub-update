import 'package:flutter/material.dart';

import '../models/discovered_card_state.dart';

/// Device card — a pure component (CDD).
///
/// Renders [DiscoveredCardState] and nothing else. No streams, no session,
/// no catalog lookup, no HID. The parent owns the data and passes it in.
///
/// Used for every device type (mouse, keyboard). Only the verified case is
/// rendered; the parent decides whether to build this card at all.
class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key, required this.state});

  final DiscoveredCardState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Image.asset(state.imageSmall),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.displayName, style: _title),
                  const SizedBox(height: 4),
                  Text(_modeLabel, style: _subtitle),
                  const SizedBox(height: 4),
                  Text(_batteryLabel, style: _subtitle),
                  const SizedBox(height: 4),
                  Text(_firmwareLabel, style: _subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _modeLabel =>
      state.connectionMode == 0 ? 'USB' : state.connectionMode == 1 ? '2.4G' : '—';

  String get _batteryLabel {
    if (state.batteryPercentage < 0) return 'Battery —';
    final pct = '${state.batteryPercentage}%';
    return state.isCharging ? '$pct ⚡ charging' : 'Battery $pct';
  }

  String get _firmwareLabel =>
      state.firmwareVersion.isEmpty ? 'Firmware —' : 'Firmware ${state.firmwareVersion}';

  static const _title = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  static const _subtitle = TextStyle(fontSize: 13, color: Colors.grey);
}
