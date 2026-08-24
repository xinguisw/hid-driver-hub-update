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
          // Left: device image centered.
          if (card.imageLarge.isNotEmpty)
            Image.asset(
              card.imageLarge,
              width: isWide ? 320 : 220,
              fit: BoxFit.contain,
            ),
          SizedBox(width: isWide ? 64 : 0, height: isWide ? 0 : 32),
          // Right: firmware info container + reset button.
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _FirmwareBox(
                title: 'Mouse Firmware Version',
                version: mouseVersion,
              ),
              const SizedBox(height: 16),
              _FirmwareBox(
                title: 'Dongle Firmware Version',
                version: dongleVersion,
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () {}, // active UI state
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('Reset to Default'),
                style: _devicePanelOutlinedButtonStyle(context),
              ),
            ],
          ),
        ];

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isWide
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
  const _FirmwareBox({required this.title, required this.version});

  final String title;
  final String version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBorderColor = (isDark ? Colors.white : Colors.black).withValues(
      alpha: 0.45,
    );

    return Container(
      width: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: cardBorderColor, width: 1.0),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.15,
                    ),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  version,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {},
                style: _devicePanelOutlinedButtonStyle(context).copyWith(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                child: const Text(
                  'Check for Updates',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.system_update_alt_rounded, size: 18),
              label: const Text('Update Firmware'),
              style: _devicePanelPrimaryButtonStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}

ButtonStyle _devicePanelOutlinedButtonStyle(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return OutlinedButton.styleFrom(
    backgroundColor: isDark ? const Color(0xFF26282E) : Colors.white,
    foregroundColor: theme.colorScheme.onSurface,
    side: BorderSide(
      color: (isDark ? const Color(0xFF3F424B) : const Color(0xFFD0D5DD)),
      width: 1.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    elevation: 1.5,
    shadowColor: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
  );
}

ButtonStyle _devicePanelPrimaryButtonStyle(BuildContext context) {
  final theme = Theme.of(context);
  return FilledButton.styleFrom(
    backgroundColor: theme.colorScheme.primary,
    foregroundColor: Colors.white,
    elevation: 3,
    shadowColor: theme.colorScheme.primary.withValues(alpha: 0.35),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
  );
}
