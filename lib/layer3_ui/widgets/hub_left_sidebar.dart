import 'package:driver_hub/layer3_ui/widgets/hub_button_mapping_panel.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Left hub nav — compact device header + destinations + collapse toggle.
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

  final bool hasRgbBacklight;
  final VoidCallback? onDeviceTap;

  @override
  State<HubLeftSidebar> createState() => _HubLeftSidebarState();
}

class _HubLeftSidebarState extends State<HubLeftSidebar> {
  bool _extended = true;

  static const double _collapsedWidth = 72;
  static const double _extendedWidth = 256;
  static const Duration _animationDuration = Duration(milliseconds: 250);
  static const Curve _animationCurve = Curves.easeInOutCubic;

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

    final isDark = theme.brightness == Brightness.dark;
    final suffix = isDark ? 'white' : 'black';

    return TapRegion(
      groupId: hubButtonMappingTapRegionId,
      child: AnimatedContainer(
        duration: _animationDuration,
        curve: _animationCurve,
        width: width,
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Device Header ----
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: _deviceHeader(theme),
            ),

            // ---- Destination List ----
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  final destination = _destinations[index];
                  final selected = destination.index == widget.selectedIndex;
                  final label = destination.label;

                  return InkWell(
                    onTap: () =>
                        widget.onDestinationSelected(destination.index),
                    child: AnimatedContainer(
                      duration: _animationDuration,
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

            // ---- Smooth Rotating Collapse Toggle ----
            Align(
              alignment: _extended ? Alignment.centerRight : Alignment.center,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _extended = !_extended),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AnimatedRotation(
                    turns: _extended ? 0.0 : 0.5, // Rotates 180 degrees
                    duration: _animationDuration,
                    curve: _animationCurve,
                    child: Icon(
                      Icons.chevron_left,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  /// Animated device header transition
  Widget _deviceHeader(ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: widget.onDeviceTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: AnimatedCrossFade(
          duration: _animationDuration,
          firstCurve: _animationCurve,
          secondCurve: _animationCurve,
          crossFadeState: _extended
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _expandedHeaderContent(theme),
          secondChild: _collapsedHeaderContent(theme),
        ),
      ),
    );
  }

  /// Expanded Header View
  Widget _expandedHeaderContent(ThemeData theme) {
    final subStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              widget.card.connectionMode == 0 ? Icons.cable : Icons.wifi,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(_modeLabel, style: subStyle),
            const SizedBox(width: 12),
            Icon(
              _batteryIcon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(_batteryLabel, style: subStyle),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          widget.card.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Collapsed Header View
  Widget _collapsedHeaderContent(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mouse,
            size: 22,
            color: theme.colorScheme.onSurfaceVariant,
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

  /// Maps battery state to the corresponding Material icon.
  IconData get _batteryIcon {
    if (widget.card.isCharging) {
      return Icons.battery_charging_full;
    }
    final pct = widget.card.batteryPercentage;
    if (pct < 0) {
      return Icons.battery_alert;
    }
    if (pct >= 85) {
      return Icons.battery_full;
    }
    if (pct >= 60) {
      return Icons.battery_5_bar;
    }
    if (pct >= 35) {
      return Icons.battery_3_bar;
    }
    if (pct >= 15) {
      return Icons.battery_1_bar;
    }
    return Icons.battery_alert;
  }

  /// Destination row with fixed icon slot and fading label
  Widget _destinationRow({
    required String label,
    required String iconName,
    required String suffix,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: SvgPicture.asset(
              'assets/images/${iconName}_$suffix.svg',
              width: 20,
              height: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _extended ? 1.0 : 0.0,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              softWrap: false,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}
