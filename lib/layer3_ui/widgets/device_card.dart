import 'package:flutter/material.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';

/// Modern grid‑style device card with hover effects, keyboard detection,
/// and full information (name, firmware, battery percentage + icon).
class DeviceCard extends StatefulWidget {
  const DeviceCard({super.key, required this.state, this.onTap});

  final DiscoveredCardState state;
  final VoidCallback? onTap;

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool _isHovered = false;

  bool get _isKeyboard {
    final name = widget.state.displayName.toUpperCase();
    final devId = widget.state.devId.toUpperCase();
    return name.contains('KB') ||
        name.contains('KEYBOARD') ||
        devId.contains('KB');
  }

  @override
  Widget build(BuildContext context) {
    final isKb = _isKeyboard;
    final cardWidth = isKb ? 540.0 : 250.0;
    const cardHeight = 350.0;

    final theme = Theme.of(context);
    final borderColor = _isHovered
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    final textColor = theme.colorScheme.onSurface;
    final iconColor = theme.colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: _isHovered ? 1.5 : 1.0),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ---- Device image (centered) ----
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        widget.state.imageSmall,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          if (!isKb) {
                            return Image.asset(
                              'assets/images/m7xse/small.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.mouse_outlined,
                                size: 90,
                                color: iconColor.withValues(alpha: 0.5),
                              ),
                            );
                          }
                          return Icon(
                            Icons.keyboard_outlined,
                            size: 110,
                            color: iconColor.withValues(alpha: 0.5),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---- Device Model Name ----
                  Text(
                    widget.state.displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ---- Firmware version (from Version 1) ----
                  Text(
                    widget.state.firmwareVersion.isEmpty
                        ? 'Firmware —'
                        : 'Firmware ${widget.state.firmwareVersion}',
                    style: TextStyle(color: iconColor, fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  // ---- Status row: Mode icon + Battery icon + Battery text ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Connection mode
                      Icon(
                        widget.state.connectionMode == 0
                            ? Icons.cable
                            : Icons.wifi,
                        size: 22,
                        color: iconColor,
                      ),
                      const SizedBox(width: 16),

                      // Battery icon
                      Icon(_batteryIcon, size: 22, color: iconColor),
                      const SizedBox(width: 6),

                      // Battery percentage text (with charging indicator)
                      Text(
                        _batteryLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: iconColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Battery icon logic (unchanged from Version 2)
  IconData get _batteryIcon {
    if (widget.state.isCharging) {
      return Icons.battery_charging_full;
    }
    final pct = widget.state.batteryPercentage;
    if (pct < 0) return Icons.battery_unknown;
    if (pct >= 90) return Icons.battery_full;
    if (pct >= 70) return Icons.battery_5_bar;
    if (pct >= 50) return Icons.battery_4_bar;
    if (pct >= 30) return Icons.battery_2_bar;
    if (pct >= 10) return Icons.battery_1_bar;
    return Icons.battery_alert;
  }

  /// Battery label (from Version 1, adapted)
  String get _batteryLabel {
    if (widget.state.batteryPercentage < 0) return '—';
    final pct = '${widget.state.batteryPercentage}%';
    return widget.state.isCharging ? '$pct ⚡' : pct;
  }
}
