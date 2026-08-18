import 'package:flutter/material.dart';
import 'package:driver_hub/i18n/strings.g.dart';

/// Empty-device placeholder — a pure atom (CDD).
///
/// Shown when no device is verified. Renders a busy or idle message. No
/// lifecycle, no data; the parent decides whether to build it.
class EmptyDeviceState extends StatelessWidget {
  const EmptyDeviceState({
    super.key,
    required this.busy,
    required this.onAddDevice,
  });

  final bool busy;
  final VoidCallback onAddDevice;

  @override
  //Change from center to alignment for better positioning of the button
  Widget build(BuildContext context) {
    // why: Use theme colors for high contrast and dark/light mode compliance
    final theme = Theme.of(context);
    final buttonBg = theme.brightness == Brightness.dark
        ? theme.colorScheme.primary
        : Colors.black;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: busy ? null : onAddDevice,
              icon: const Icon(Icons.add, color: Colors.white, size: 16),
              label: Text(
                busy ? t.devices.working : t.devices.addDevice,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: buttonBg,
                foregroundColor: Colors.white,
                disabledBackgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.26,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.devices.bluetoothWarning,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
