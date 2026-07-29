import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter/material.dart';

/// Button Mapping right pane — action catalog (skeleton).
///
/// L3 only. Tabs paint L4-packed catalogs (assets via L2). No catalog
/// ownership, no L5/HID. Row tap = local highlight only.
class HubButtonMappingPanel extends StatefulWidget {
  const HubButtonMappingPanel({
    super.key,
    this.selectedButtonId,
    this.mouseActionCatalog,
    this.keyboardActionCatalog,
    this.specialActionCatalog,
  });

  final int? selectedButtonId;
  final List<ActionCatalogSectionData>? mouseActionCatalog;
  final List<ActionCatalogSectionData>? keyboardActionCatalog;
  final List<ActionCatalogSectionData>? specialActionCatalog;

  static const double width = 280;

  @override
  State<HubButtonMappingPanel> createState() => _HubButtonMappingPanelState();
}

class _HubButtonMappingPanelState extends State<HubButtonMappingPanel> {
  static const _tabs = ['Mouse', 'Keyboard', 'Special', 'Macro'];

  int _tabIndex = 0;
  String? _selectedCatalogId;
  // Special combination UI (local only — not staged).
  final Set<String> _specialMods = {};

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
              child: switch (_tabIndex) {
                0 => _SectionCatalogList(
                    sections: widget.mouseActionCatalog ?? const [],
                    selectedId: _selectedCatalogId,
                    onSelect: (id) => setState(() => _selectedCatalogId = id),
                  ),
                1 => _SectionCatalogList(
                    sections: widget.keyboardActionCatalog ?? const [],
                    selectedId: _selectedCatalogId,
                    onSelect: (id) => setState(() => _selectedCatalogId = id),
                  ),
                2 => _SpecialCombinationBody(
                    sections: widget.specialActionCatalog ?? const [],
                    selectedMods: _specialMods,
                    onToggleMod: (id) {
                      setState(() {
                        if (_specialMods.contains(id)) {
                          _specialMods.remove(id);
                        } else {
                          _specialMods.add(id);
                        }
                      });
                    },
                  ),
                _ => const SizedBox.expand(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCatalogList extends StatelessWidget {
  const _SectionCatalogList({
    required this.sections,
    required this.selectedId,
    required this.onSelect,
  });

  final List<ActionCatalogSectionData> sections;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (sections.isEmpty) return const SizedBox.expand();
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

/// Special tab skeleton — Combination Keys from catalog roles (ref).
class _SpecialCombinationBody extends StatelessWidget {
  const _SpecialCombinationBody({
    required this.sections,
    required this.selectedMods,
    required this.onToggleMod,
  });

  final List<ActionCatalogSectionData> sections;
  final Set<String> selectedMods;
  final ValueChanged<String> onToggleMod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (sections.isEmpty) return const SizedBox.expand();
    final section = sections.first;
    final mods = [
      for (final i in section.items)
        if (i.role == 'modifier') i,
    ];
    final anyKey = section.items.cast<ActionCatalogItemData?>().firstWhere(
          (i) => i?.role == 'any_key',
          orElse: () => null,
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        Text(
          section.title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text('Modifier key', style: theme.textTheme.bodySmall),
            ),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in mods)
                    Material(
                      color: selectedMods.contains(m.id)
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                      child: InkWell(
                        onTap: () => onToggleMod(m.id),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            m.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: selectedMods.contains(m.id)
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 88,
              child: Text(
                anyKey?.label ?? 'Any key',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
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
