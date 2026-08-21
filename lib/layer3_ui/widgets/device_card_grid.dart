import 'package:flutter/material.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer3_ui/widgets/device_card.dart';

/// Grid of device cards — a pure composite (CDD).
///
/// Renders one [DeviceCard] per entry. No lifecycle, no watcher, no HID. The
/// parent owns the list and passes it in; this widget only lays it out.
class DeviceCardGrid extends StatelessWidget {
  const DeviceCardGrid({super.key, required this.cards, this.onCardTap});

  final List<DiscoveredCardState> cards;

  /// Called when a card is tapped; parent navigates (e.g. settings).
  final void Function(DiscoveredCardState card)? onCardTap;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          runSpacing: 24,
          children: [
            for (final state in cards)
              DeviceCard(
                state: state,
                onTap: onCardTap == null ? null : () => onCardTap!(state),
              ),
          ],
        ),
      ),
    );
  }
}
