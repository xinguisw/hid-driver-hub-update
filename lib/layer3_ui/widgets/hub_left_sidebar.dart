import 'package:driver_hub/layer3_ui/widgets/device_card.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:flutter/material.dart';

/// Left hub nav — device on top, destinations with `x` + label, toggle bottom.
///
/// L3 presentational. No L4/L5.
///
/// why: stock [NavigationRail] +8px overflow while extended animates. This pane
/// owns width. [DeviceCard] only when extended (Card Row needs ~256px); collapsed
/// shows image thumb only so Card is never laid out under 72px.
class HubLeftSidebar extends StatefulWidget {
  const HubLeftSidebar({
    super.key,
    required this.card,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onDeviceTap,
  });

  final DiscoveredCardState card;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onDeviceTap;

  @override
  State<HubLeftSidebar> createState() => _HubLeftSidebarState();
}

class _HubLeftSidebarState extends State<HubLeftSidebar> {
  bool _extended = true;

  static const double _collapsedWidth = 72;
  static const double _extendedWidth = 256;

  static const _labels = <String>[
    'Button Mapping',
    'Macro Setting',
    'Performance Setting',
    'Parameter Setting',
    'Backlight Setting',
    'Profile Management',
    'Device Setting',
  ];

  @override
  Widget build(BuildContext context) {
    final width = _extended ? _extendedWidth : _collapsedWidth;
    final theme = Theme.of(context);

    // why: jump width (no AnimatedContainer) so DeviceCard never mid-animates
    // into ~40px (that was the 60px right overflow on device_card Row)
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: _extended ? _extendedDevice() : _collapsedDevice(),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _labels.length,
              itemBuilder: (context, index) {
                final selected = index == widget.selectedIndex;
                final label = _labels[index];
                return InkWell(
                  onTap: () => widget.onDestinationSelected(index),
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
                  child: Center(
                    child: Text(_extended ? '<' : '>'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `x` always kept; full label only when extended.
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
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _extendedDevice() {
    return DeviceCard(
      state: widget.card,
      onTap: widget.onDeviceTap,
    );
  }

  Widget _collapsedDevice() {
    return InkWell(
      onTap: widget.onDeviceTap,
      child: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: Image.asset(
            widget.card.imageSmall,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
