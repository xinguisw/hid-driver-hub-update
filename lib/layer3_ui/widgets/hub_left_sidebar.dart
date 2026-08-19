import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Left hub nav — compact device header + destinations + collapse toggle.
///
/// L3 presentational. No L4/L5.
class HubLeftSidebar extends StatefulWidget {
  const HubLeftSidebar({
    super.key,
    required this.card,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.hasRgbBacklight = false,
    this.onDeviceTap,
  });

  final DiscoveredCardState card;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Capability already packed by L4. Unsupported blocks are not navigable.
  final bool hasRgbBacklight;
  final VoidCallback? onDeviceTap;

  @override
  State<HubLeftSidebar> createState() => _HubLeftSidebarState();
}

class _HubLeftSidebarState extends State<HubLeftSidebar> {
  bool _extended = true;

  static const double _collapsedWidth = 72;
  static const double _extendedWidth = 256;

  List<({int index, String label, String iconName})> get _destinations => [
    (index: 0, label: t.sidebar.buttonMapping, iconName: 'button_mapping'),
    (index: 1, label: t.sidebar.macroSetting, iconName: 'macro'),
    (index: 2, label: t.sidebar.performanceSetting, iconName: 'performance'),
    (index: 3, label: t.sidebar.parameterSetting, iconName: 'parameter'),
    if (widget.hasRgbBacklight)
      (index: 4, label: t.sidebar.backlightSetting, iconName: 'backlight'),
    (index: 5, label: t.sidebar.profileManagement, iconName: 'profile'),
    (index: 6, label: t.sidebar.deviceSetting, iconName: 'setting'),
    (index: 7, label: 'App Setting', iconName: 'setting'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = _extended ? _extendedWidth : _collapsedWidth;
    final theme = Theme.of(context);

    //  Determine light/dark mode suffix for SVGs
    final isDark = theme.brightness == Brightness.dark;
    final suffix = isDark ? 'white' : 'black';

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: _deviceHeader(theme, suffix),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _destinations.length,
              itemBuilder: (context, index) {
                final destination = _destinations[index];
                final selected = destination.index == widget.selectedIndex;
                final label = destination.label;

                return InkWell(
                  onTap: () => widget.onDestinationSelected(destination.index),
                  child: ColoredBox(
                    color: selected
                        ? theme.colorScheme.secondaryContainer.withValues(
                            alpha: 0.5,
                          )
                        : Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: _destinationRow(
                        label: label,
                        iconName: destination.iconName,
                        suffix: suffix,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: _extended ? Alignment.centerRight : Alignment.center,
            child: InkWell(
              onTap: () => setState(() => _extended = !_extended),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  _extended ? Icons.chevron_left : Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact header showing device connection, battery info, and title.
  Widget _deviceHeader(ThemeData theme, String suffix) {
    final name = widget.card.displayName;
    final subStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return InkWell(
      onTap: widget.onDeviceTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: _extended
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Mode Icon + Label
                      SvgPicture.asset(
                        widget.card.connectionMode == 0
                            ? 'assets/images/usb_$suffix.svg'
                            : 'assets/images/2p4g_$suffix.svg',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(_modeLabel, style: subStyle),
                      const SizedBox(width: 12),

                      // Battery Icon + Label
                      SvgPicture.asset(
                        _getBatterySvgPath(suffix),
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(_batteryLabel, style: subStyle),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/mouse_$suffix.svg',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.sidebar.mouse,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String get _modeLabel {
    final m = widget.card.connectionMode;
    if (m == 0) {
      return 'USB';
    }
    if (m == 1) {
      return '2.4G';
    }
    return '—';
  }

  String get _batteryLabel {
    final pct = widget.card.batteryPercentage;
    if (pct < 0) {
      return t.sidebar.batteryEmpty;
    }
    if (widget.card.isCharging) {
      return t.sidebar.batteryCharging(pct: pct.toString());
    }
    return t.sidebar.batteryLabel(pct: pct.toString());
  }

  String _getBatterySvgPath(String suffix) {
    if (widget.card.isCharging) {
      return 'assets/images/battery_charging_$suffix.svg';
    }
    final pct = widget.card.batteryPercentage;
    if (pct < 0) return 'assets/images/battery_alert_$suffix.svg';
    if (pct >= 85) return 'assets/images/battery_100_$suffix.svg';
    if (pct >= 60) return 'assets/images/battery_75_$suffix.svg';
    if (pct >= 35) return 'assets/images/battery_50_$suffix.svg';
    if (pct >= 15) return 'assets/images/battery_25_$suffix.svg';
    return 'assets/images/battery_alert_$suffix.svg';
  }

  Widget _destinationRow({
    required String label,
    required String iconName,
    required String suffix,
  }) {
    final iconWidget = SvgPicture.asset(
      'assets/images/${iconName}_$suffix.svg',
      width: 20,
      height: 20,
    );

    if (!_extended) {
      return Center(child: iconWidget);
    }

    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
