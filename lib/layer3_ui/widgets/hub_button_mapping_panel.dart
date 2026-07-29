import 'package:driver_hub/layer3_ui/catalog/hub_mouse_action_catalog.dart';
import 'package:flutter/material.dart';

/// Button Mapping right pane — action catalog (skeleton).
///
/// L3 only. Tabs Mouse / Keyboard / Special / Macro. Mouse tab = hardcoded
/// list from [kHubMouseActionCatalog]; other tabs empty. No L4/L5/HID.
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
  // why: local UI highlight only — not staged mapping yet
  String? _selectedCatalogId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: HubButtonMappingPanel.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              child: _tabIndex == 0
                  ? _MouseCatalogList(
                      sections: kHubMouseActionCatalog,
                      selectedId: _selectedCatalogId,
                      onSelect: (id) => setState(() => _selectedCatalogId = id),
                    )
                  : const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MouseCatalogList extends StatelessWidget {
  const _MouseCatalogList({
    required this.sections,
    required this.selectedId,
    required this.onSelect,
  });

  final List<HubCatalogSection> sections;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        for (final section in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              section.title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final item in section.items)
            Material(
              color: item.id == selectedId
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(item.id),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    item.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: item.id == selectedId
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
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
