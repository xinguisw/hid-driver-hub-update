import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:flutter/material.dart';

/// Left hub nav — compact device header + destinations + collapse toggle.
///
/// L3 presentational. No L4/L5.
///
/// Device header skeleton: name + mode + battery/charging text.
/// No image, no firmware. Mode/battery as icons later.
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

  List<({int index, String label})> get _destinations => [
    (index: 0, label: 'Button Mapping'),
    (index: 1, label: 'Macro Setting'),
    (index: 2, label: 'Performance Setting'),
    (index: 3, label: 'Parameter Setting'),
    if (widget.hasRgbBacklight) (index: 4, label: 'Backlight Setting'),
    (index: 5, label: 'Profile Management'),
    (index: 6, label: 'Device Setting'),
    (index: 7, label: 'App Setting'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = _extended ? _extendedWidth : _collapsedWidth;
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: _deviceHeader(theme),
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
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: _destinationRow(label),
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => setState(() => _extended = !_extended),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(child: Text(_extended ? '<' : '>')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton: name + mode + battery/charging (text; icons later).
  Widget _deviceHeader(ThemeData theme) {
    final name = widget.card.displayName;
    final subStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return InkWell(
      onTap: widget.onDeviceTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _extended
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // why: ref — mode/battery row on top; model name at bottom
                  Text(_modeLabel, style: subStyle),
                  const SizedBox(height: 2),
                  Text(_batteryLabel, style: subStyle),
                  const SizedBox(height: 4),
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
            // why: collapsed rail — text stand-in "mouse" (not first letter of name)
            : Center(
                child: Text(
                  'mouse',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }

  String get _modeLabel {
    final m = widget.card.connectionMode;
    if (m == 0) return 'USB';
    if (m == 1) return '2.4G';
    return '—';
  }

  String get _batteryLabel {
    final pct = widget.card.batteryPercentage;
    if (pct < 0) return 'Battery —';
    if (widget.card.isCharging) return 'Battery $pct% charging';
    return 'Battery $pct%';
  }

  Widget _destinationRow(String label) {
    const xIcon = SizedBox(
      width: 24,
      height: 24,
      child: Center(child: Text('x')),
    );
    if (!_extended) {
      return const Center(child: xIcon);
    }
    return Row(
      children: [
        xIcon,
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
