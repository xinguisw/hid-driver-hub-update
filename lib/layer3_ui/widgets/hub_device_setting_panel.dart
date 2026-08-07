import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:flutter/material.dart';

/// Device Setting page — device image (left) + firmware info (right).
///
/// Skeleton: read-only display. Update / Check / Reset are inert (null).
/// Firmware block title follows the flow: connectionMode USB → Mouse,
/// 2.4G → Dongle. Version comes from the L4 card snapshot.
class HubDeviceSettingPanel extends StatelessWidget {
  const HubDeviceSettingPanel({super.key, required this.card});

  final DiscoveredCardState card;

  @override
  Widget build(BuildContext context) {
    final onUsb = card.connectionMode == 0;
    final title = onUsb ? 'Mouse Firmware Version' : 'Dongle Firmware Version';
    final version =
        card.firmwareVersion.isEmpty ? '—' : card.firmwareVersion;

    // Both halves hug the center instead of spreading to the edges.
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: device image.
          if (card.imageLarge.isNotEmpty)
            Image.asset(card.imageLarge, width: 220, fit: BoxFit.contain),
          const SizedBox(width: 64),
          // Right: firmware info container + reset (fixed width, centered col).
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 320,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Latest version'),
                        const SizedBox(width: 12),
                        Text(version),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: null, // skeleton — not wired yet
                          child: const Text('Check updates'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: null, // skeleton — not wired yet
                        child: const Text('New version & update'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: OutlinedButton(
                  onPressed: null, // skeleton — not wired yet
                  child: const Text('RESET TO DEFAULT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
