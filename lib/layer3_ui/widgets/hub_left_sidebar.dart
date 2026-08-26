import 'package:driver_hub/layer3_ui/widgets/hub_button_mapping_panel.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter/material.dart';

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

  List<({int index, String label, IconData icon})> get _destinations => [
    (index: 0, label: t.sidebar.buttonMapping, icon: Icons.ads_click_outlined),
    (index: 1, label: t.sidebar.macroSetting, icon: Icons.integration_instructions_outlined),
    (index: 2, label: t.sidebar.performanceSetting, icon: Icons.speed_outlined),
    (index: 3, label: t.sidebar.parameterSetting, icon: Icons.tune_outlined),
    if (widget.hasRgbBacklight)
      (index: 4, label: t.sidebar.backlightSetting, icon: Icons.lightbulb_outlined),
    (index: 5, label: t.sidebar.profileManagement, icon: Icons.account_circle_outlined),
    (index: 6, label: t.sidebar.deviceSetting, icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final width = _extended ? _extendedWidth : _collapsedWidth;
    final theme = Theme.of(context);

    return TapRegion(
      groupId: hubButtonMappingTapRegionId,
      child: AnimatedContainer(
        duration: _animationDuration,
        curve: _animationCurve,
        width: width,
        child: ClipRect(
          child: RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, constraints) {
              final toggle = Align(
                alignment: _extended ? Alignment.centerRight : Alignment.center,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _extended = !_extended),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: AnimatedRotation(
                        turns: _extended ? 0.0 : 0.5,
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
              );

              if (constraints.maxHeight < 280) {
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                      child: _deviceHeader(theme),
                    ),
                    for (final destination in _destinations)
                      _buildDestinationTile(
                        context,
                        theme,
                        destination,
                      ),
                    toggle,
                  ],
                );
              }

              return Column(
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
                        return _buildDestinationTile(
                          context,
                          theme,
                          _destinations[index],
                        );
                      },
                    ),
                  ),

                  // ---- Smooth Rotating Collapse Toggle ----
                  toggle,
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildDestinationTile(
    BuildContext context,
    ThemeData theme,
    ({int index, String label, IconData icon}) destination,
  ) {
    final selected = destination.index == widget.selectedIndex;
    final label = destination.label;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      child: Material(
        color: selected
            ? theme.colorScheme.onSurface.withValues(
                alpha: 0.08,
              )
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          canRequestFocus: false,
          focusColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          onTap: () => widget.onDestinationSelected(destination.index),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: _destinationRow(
                label: label,
                icon: destination.icon,
                theme: theme,
                isSelected: selected,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Animated device header transition
  Widget _deviceHeader(ThemeData theme) {
    return Tooltip(
      message: t.sidebar.back,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
      return '—';
    }
    return '$pct%';
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
    required IconData icon,
    required ThemeData theme,
    required bool isSelected,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isSelected
        ? theme.colorScheme.onSurface
        : (isDark ? Colors.white70 : theme.colorScheme.onSurfaceVariant);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _extended ? 1.0 : 0.0,
          child: SizedBox(
            width: 160,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              softWrap: false,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
