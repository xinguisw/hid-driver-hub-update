import 'package:flutter/material.dart';

import '../models/discovered_card_state.dart';
import 'device_card.dart';

/// Grid of device cards — a pure composite (CDD).
///
/// Renders one [DeviceCard] per entry. No lifecycle, no watcher, no HID. The
/// parent owns the list and passes it in; this widget only lays it out.
class DeviceCardGrid extends StatelessWidget {
  const DeviceCardGrid({super.key, required this.cards});

  final List<DiscoveredCardState> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return ListView(
      children: [
        for (final state in cards) DeviceCard(state: state),
      ],
    );
  }
}
