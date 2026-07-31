import 'package:flutter/material.dart';

/// Empty-device placeholder — a pure atom (CDD).
///
/// Shown when no device is verified. Renders a busy or idle message. No
/// lifecycle, no data; the parent decides whether to build it.
class EmptyDeviceState extends StatelessWidget {
  const EmptyDeviceState({super.key, required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        busy ? 'Working…' : 'No devices',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
