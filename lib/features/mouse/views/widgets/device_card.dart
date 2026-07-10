import 'package:flutter/material.dart';

import '../../models/discovered_card_state.dart';

/// Mouse card — a pure component (CDD).
///
/// Renders [DiscoveredCardState] and nothing else. No streams, no session,
/// no catalog lookup, no HID. The parent owns the data and passes it in.
///
/// Only the verified case is rendered. Unverified devices are not shown —
/// the parent decides whether to build this card at all.
///
/// [imageSmall] is shown; [DiscoveredCardState.imageLarge] is carried for the
/// future canvas and is not rendered here.
class MouseCard extends StatelessWidget {
  const MouseCard({super.key, required this.state});

  final DiscoveredCardState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _image,
            const SizedBox(width: 12),
            Expanded(child: _details),
          ],
        ),
      ),
    );
  }

  Widget get _image {
    return SizedBox(
      width: 64,
      height: 64,
      child: Image.asset(state.imageSmall),
    );
  }

  Widget get _details => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(state.displayName, style: _title),
          const SizedBox(height: 4),
          Text(_modeLabel, style: _subtitle),
          const SizedBox(height: 8),
          _row('Firmware', _firmwareLabel),
          _row('Battery', _batteryLabel),
          _row('Charging', _chargingLabel),
        ],
      );

  String get _modeLabel =>
      state.connectionMode == 0 ? 'USB' : state.connectionMode == 1 ? '2.4G' : '—';

  String get _firmwareLabel =>
      state.firmwareVersion.isEmpty ? '—' : state.firmwareVersion;

  String get _batteryLabel =>
      state.batteryPercentage < 0 ? '—' : '${state.batteryPercentage}%';

  String get _chargingLabel => state.isCharging ? 'Yes' : 'No';

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            SizedBox(
                width: 72,
                child: Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 12))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
          ],
        ),
      );

  static const _title = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  static const _subtitle = TextStyle(fontSize: 13, color: Colors.grey);
}
