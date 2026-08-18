import 'package:flutter/material.dart';
import 'package:driver_hub/i18n/strings.g.dart';

/// Empty-device placeholder — a pure atom (CDD).
///
/// Shown when no device is verified. Renders a busy or idle message. When
/// [onAddDevice] is provided and the widget is idle, an "Add device" button
/// is shown beneath the message.
///
/// No lifecycle, no data; the parent decides whether to build it.
class EmptyDeviceState extends StatelessWidget {
  const EmptyDeviceState({
    super.key,
    required this.busy,
    this.onAddDevice,
  });

  final bool busy;

  /// Called when the user taps "Add device". If null the button is omitted.
  final VoidCallback? onAddDevice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            busy ? t.devices.working : t.devices.noDevices,
            style: const TextStyle(color: Colors.grey),
          ),
          if (!busy && onAddDevice != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddDevice,
              icon: const Icon(Icons.add, size: 16),
              label: Text(t.devices.addDevice),
            ),
          ],
        ],
      ),
    );
  }
}
