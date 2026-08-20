import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

    //  Determine light/dark mode variant suffix for assets
    final isDark = theme.brightness == Brightness.dark;
    final suffix = isDark ? 'white' : 'black';

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
                      child: Transform.scale(
                        scale: isKb ? 1.0 : 1.25,
                        child: Image.asset(
                          widget.state.imageSmall,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            if (!isKb) {
                              return Image.asset(
                                'assets/images/m7xse/small.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => SvgPicture.asset(
                                  'assets/images/mouse_$suffix.svg',
                                  width: 90,
                                  height: 90,
                                ),
                              );
                            }
                            return SvgPicture.asset(
                              'assets/images/mouse_$suffix.svg',
                              width: 110,
                              height: 110,
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

                  // ---- Status row: Mode SVG + Battery SVG + Battery text ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Connection mode icon (USB or 2.4G)
                      SvgPicture.asset(
                        widget.state.connectionMode == 0
                            ? 'assets/images/usb_$suffix.svg'
                            : 'assets/images/2p4g_$suffix.svg',
                        width: 22,
                        height: 22,
                      ),
                      const SizedBox(width: 16),

                      // Battery status icon SVG
                      SvgPicture.asset(
                        _getBatterySvgPath(suffix),
                        width: 22,
                        height: 22,
                      ),
                      const SizedBox(width: 6),

                      // Battery percentage text
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

  /// Maps battery state and theme to the corresponding SVG path
  String _getBatterySvgPath(String suffix) {
    if (widget.state.isCharging) {
      return 'assets/images/battery_charging_$suffix.svg';
    }
    final pct = widget.state.batteryPercentage;
    if (pct < 0) return 'assets/images/battery_alert_$suffix.svg';
    if (pct >= 85) return 'assets/images/battery_100_$suffix.svg';
    if (pct >= 60) return 'assets/images/battery_75_$suffix.svg';
    if (pct >= 35) return 'assets/images/battery_50_$suffix.svg';
    if (pct >= 15) return 'assets/images/battery_25_$suffix.svg';
    return 'assets/images/battery_alert_$suffix.svg';
  }

  /// Battery percentage text label
  String get _batteryLabel {
    if (widget.state.batteryPercentage < 0) return '—';
    final pct = '${widget.state.batteryPercentage}%';
    return widget.state.isCharging ? '$pct ⚡' : pct;
  }
}
