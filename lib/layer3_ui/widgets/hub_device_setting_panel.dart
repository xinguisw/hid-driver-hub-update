import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:flutter/material.dart';

/// Device Setting page — device image (left) + firmware info (right).
///
/// Skeleton: read-only display. Update / Check / Reset are inert (null).
/// Both A8 firmware values are rendered independently. The device card keeps
/// the mouse value, while this page also shows the receiver/dongle value.
class HubDeviceSettingPanel extends StatelessWidget {
  const HubDeviceSettingPanel({super.key, required this.card});

  final DiscoveredCardState card;

  @override
  Widget build(BuildContext context) {
    final mouseVersion = card.mouseFirmwareVersion.isEmpty
        ? (card.firmwareVersion.isEmpty ? '—' : card.firmwareVersion)
        : card.mouseFirmwareVersion;
    final dongleVersion = card.dongleFirmwareVersion.isEmpty
        ? '—'
        : card.dongleFirmwareVersion;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final children = [
          // Left: device image.
          if (card.imageLarge.isNotEmpty)
            Image.asset(
              card.imageLarge,
              width: isWide ? 300 : 200,
              fit: BoxFit.contain,
            ),
          SizedBox(width: isWide ? 64 : 0, height: isWide ? 0 : 32),
          // Right: firmware info container + reset (fixed width, centered col).
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FirmwareBox(
                title: 'Mouse Firmware Version',
                version: mouseVersion,
                icon: Icons.mouse_outlined,
              ),
              const SizedBox(height: 16),
              _FirmwareBox(
                title: 'Dongle Firmware Version',
                version: dongleVersion,
                icon: Icons.usb_outlined,
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: null, // skeleton — not wired yet
                icon: const Icon(Icons.restore),
                label: const Text('RESET TO DEFAULT'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  side: const BorderSide(color: Colors.redAccent),
                  foregroundColor: Colors.redAccent,
                ),
              ),
            ],
          ),
        ];

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isWide
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: children,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: children,
                  ),
          ),
        );
      },
    );
  }
}

class _FirmwareBox extends StatelessWidget {
  const _FirmwareBox({
    required this.title,
    required this.version,
    required this.icon,
  });

  final String title;
  final String version;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Current Version',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  version,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Check for Updates'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.system_update_alt),
              label: const Text('Update Firmware'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
