import 'package:flutter/material.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';

/// Modern grid‑style device card with hover effects, keyboard detection,
/// and full information (name, firmware, battery percentage + icon).
class DeviceCard extends StatefulWidget {
  const DeviceCard({
    super.key,
    required this.state,
    this.onTap,
    this.width,
    this.height,
  });

  final DiscoveredCardState state;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

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

    // Use passed dimensions, or fall back to default larger sizes
    final cardWidth = widget.width ?? (isKb ? 650.0 : 300.0);
    final cardHeight = widget.height ?? 450.0;

    final theme = Theme.of(context);

    final borderColor = _isHovered
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    final textColor = theme.colorScheme.onSurface;
    final iconColor = _isHovered
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(
          maxWidth: cardWidth,
          maxHeight: cardHeight,
        ),
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
                      child: Transform.scale(
                        scale: isKb ? 1.0 : 1.25,
                        child: Image.asset(
                          isKb ? widget.state.imageSmall : widget.state.imageLarge,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            if (!isKb) {
                              return Icon(
                                Icons.mouse,
                                size: 90,
                                color: iconColor,
                              );
                            }
                            return Icon(
                              Icons.keyboard,
                              size: 110,
                              color: iconColor,
                            );
                          },
                        ),
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

                  // ---- Status row: Mode icon + Battery icon + Battery text ----
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontSize: 13,
                      color: iconColor,
                      fontWeight: FontWeight.w500,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Connection mode icon (USB or 2.4G)
                        Icon(
                          widget.state.connectionMode == 0
                              ? Icons.cable
                              : Icons.wifi,
                          size: 20,
                          color: iconColor,
                        ),
                        if (!widget.state.isAwake) ...[
                          const SizedBox(width: 14),
                          Icon(
                            Icons.bedtime_outlined,
                            size: 18,
                            color: iconColor,
                          ),
                          const SizedBox(width: 5),
                          const Text('Sleeping'),
                        ] else ...[
                          const SizedBox(width: 14),

                          // Battery status icon
                          Icon(_batteryIcon, size: 20, color: iconColor),
                          const SizedBox(width: 5),

                          // Battery percentage text
                          Text(_batteryLabel),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Maps battery state to the corresponding Material icon.
  IconData get _batteryIcon {
    if (widget.state.isCharging) {
      return Icons.battery_charging_full;
    }
    final pct = widget.state.batteryPercentage;
    if (pct < 0) return Icons.battery_alert;
    if (pct >= 85) return Icons.battery_full;
    if (pct >= 60) return Icons.battery_5_bar;
    if (pct >= 35) return Icons.battery_3_bar;
    if (pct >= 15) return Icons.battery_1_bar;
    return Icons.battery_alert;
  }

  /// Battery percentage text label
  String get _batteryLabel {
    if (widget.state.batteryPercentage < 0) return '—';
    return '${widget.state.batteryPercentage}%';
  }
}
