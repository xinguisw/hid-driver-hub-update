import 'package:flutter/material.dart';

/// Button Mapping right pane — **action catalog** shell (skeleton).
///
/// L3 only. Tabs Mouse / Keyboard / Special / Macro fill the panel width
/// (no horizontal scroll, no swipe animation). Bodies empty for now.
class HubButtonMappingPanel extends StatefulWidget {
  const HubButtonMappingPanel({
    super.key,
    this.selectedButtonId,
  });

  final int? selectedButtonId;

  static const double width = 280;

  @override
  State<HubButtonMappingPanel> createState() => _HubButtonMappingPanelState();
}

class _HubButtonMappingPanelState extends State<HubButtonMappingPanel> {
  static const _tabs = ['Mouse', 'Keyboard', 'Special', 'Macro'];

  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: HubButtonMappingPanel.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // why: equal-width tabs, full row visible — no horizontal scroll
          Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _TabChip(
                    label: _tabs[i],
                    selected: i == _tabIndex,
                    onTap: () => setState(() => _tabIndex = i),
                  ),
                ),
            ],
          ),
          Expanded(
            child: ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.35),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primary : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
