import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Button Mapping right pane — action catalog (skeleton).
///
/// L3 only. Tabs paint L4-packed catalogs (assets via L2). No catalog
/// ownership, no L5/HID. Row tap / Special combo = local UI only.
class HubButtonMappingPanel extends StatefulWidget {
  const HubButtonMappingPanel({
    super.key,
    this.selectedButtonId,
    this.mouseActionCatalog,
    this.keyboardActionCatalog,
    this.specialActionCatalog,
    this.onActionSelected,
    this.onComboSelected,
  });

  final int? selectedButtonId;
  final List<ActionCatalogSectionData>? mouseActionCatalog;
  final List<ActionCatalogSectionData>? keyboardActionCatalog;
  final List<ActionCatalogSectionData>? specialActionCatalog;

  /// Called when user selects a catalog action (Mouse/Keyboard tabs).
  final ValueChanged<String>? onActionSelected;

  /// Called when user completes a special combo (modifiers + key).
  final void Function(List<String> modifierIds, String keyChar)? onComboSelected;

  static const double width = 280;

  /// Product: combination shortcut allows at most two modifiers.
  static const int maxSpecialModifiers = 2;

  @override
  State<HubButtonMappingPanel> createState() => _HubButtonMappingPanelState();
}

class _HubButtonMappingPanelState extends State<HubButtonMappingPanel> {
  static const _tabs = ['Mouse', 'Keyboard', 'Special', 'Macro'];

  int _tabIndex = 0;
  String? _selectedCatalogId;

  /// Special mods in selection order (FIFO when over max).
  final List<String> _specialModOrder = [];

  /// Any-key field: listening for one character, then disengages.
  bool _anyKeyListening = false;
  String? _anyKeyChar;
  final FocusNode _anyKeyFocus = FocusNode();

  @override
  void dispose() {
    _anyKeyFocus.dispose();
    super.dispose();
  }

  void _setTab(int i) {
    setState(() {
      _tabIndex = i;
      if (i != 2) {
        _anyKeyListening = false;
      }
    });
  }

  void _toggleSpecialMod(String id) {
    setState(() {
      if (_specialModOrder.contains(id)) {
        _specialModOrder.remove(id);
        return;
      }
      // At max: drop oldest so the new pick can light; always ≤ 2 selected.
      if (_specialModOrder.length >= HubButtonMappingPanel.maxSpecialModifiers) {
        _specialModOrder.removeAt(0);
      }
      _specialModOrder.add(id);
    });
  }

  void _onAnyKeyFieldTap() {
    setState(() {
      _anyKeyListening = true;
      // why: click again to change — wait for a new key; keep old until captured
    });
    _anyKeyFocus.requestFocus();
  }

  KeyEventResult _onAnyKeyEvent(FocusNode node, KeyEvent event) {
    if (!_anyKeyListening) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    String? ch;

    // Try character first (printable keys: letters, digits, symbols)
    final raw = event.character;
    if (raw != null && raw.isNotEmpty && raw.characters.first.codeUnitAt(0) >= 0x20) {
      ch = raw.characters.first;
    } else {
      // Map logical keys to their character representations
      ch = _logicalKeyToChar[event.logicalKey];
    }

    if (ch == null) return KeyEventResult.ignored;

    setState(() {
      _anyKeyChar = ch;
      _anyKeyListening = false;
    });

    // Dispatch combo if modifiers are selected
    if (_specialModOrder.isNotEmpty) {
      widget.onComboSelected?.call(
        List<String>.from(_specialModOrder),
        ch,
      );
    }

    return KeyEventResult.handled;
  }

  /// Map logical keys to their character representations for special keys.
  static final Map<LogicalKeyboardKey, String> _logicalKeyToChar = {
    LogicalKeyboardKey.escape: 'Esc',
    LogicalKeyboardKey.enter: 'Enter',
    LogicalKeyboardKey.tab: 'Tab',
    LogicalKeyboardKey.backspace: 'Backspace',
    LogicalKeyboardKey.space: ' ',
    LogicalKeyboardKey.arrowUp: '↑',
    LogicalKeyboardKey.arrowDown: '↓',
    LogicalKeyboardKey.arrowLeft: '←',
    LogicalKeyboardKey.arrowRight: '→',
    LogicalKeyboardKey.home: 'Home',
    LogicalKeyboardKey.end: 'End',
    LogicalKeyboardKey.pageUp: 'PgUp',
    LogicalKeyboardKey.pageDown: 'PgDn',
    LogicalKeyboardKey.insert: 'Ins',
    LogicalKeyboardKey.delete: 'Del',
    LogicalKeyboardKey.f1: 'F1',
    LogicalKeyboardKey.f2: 'F2',
    LogicalKeyboardKey.f3: 'F3',
    LogicalKeyboardKey.f4: 'F4',
    LogicalKeyboardKey.f5: 'F5',
    LogicalKeyboardKey.f6: 'F6',
    LogicalKeyboardKey.f7: 'F7',
    LogicalKeyboardKey.f8: 'F8',
    LogicalKeyboardKey.f9: 'F9',
    LogicalKeyboardKey.f10: 'F10',
    LogicalKeyboardKey.f11: 'F11',
    LogicalKeyboardKey.f12: 'F12',
  };

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
                    onTap: () => _setTab(i),
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
                    onSelect: (id) {
                      setState(() => _selectedCatalogId = id);
                      widget.onActionSelected?.call(id);
                    },
                  ),
                1 => _SectionCatalogList(
                    sections: widget.keyboardActionCatalog ?? const [],
                    selectedId: _selectedCatalogId,
                    onSelect: (id) {
                      setState(() => _selectedCatalogId = id);
                      widget.onActionSelected?.call(id);
                    },
                  ),
                2 => _SpecialCombinationBody(
                    sections: widget.specialActionCatalog ?? const [],
                    selectedMods: _specialModOrder.toSet(),
                    onToggleMod: _toggleSpecialMod,
                    anyKeyChar: _anyKeyChar,
                    anyKeyListening: _anyKeyListening,
                    anyKeyFocus: _anyKeyFocus,
                    onAnyKeyTap: _onAnyKeyFieldTap,
                    onAnyKeyEvent: _onAnyKeyEvent,
                    onComboComplete: (keyChar) {
                      if (_specialModOrder.isNotEmpty) {
                        widget.onComboSelected?.call(
                          List<String>.from(_specialModOrder),
                          keyChar,
                        );
                      }
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

/// Special tab — Combination Keys; max 2 mods; Any key = one char then idle.
class _SpecialCombinationBody extends StatelessWidget {
  const _SpecialCombinationBody({
    required this.sections,
    required this.selectedMods,
    required this.onToggleMod,
    required this.anyKeyChar,
    required this.anyKeyListening,
    required this.anyKeyFocus,
    required this.onAnyKeyTap,
    required this.onAnyKeyEvent,
    required this.onComboComplete,
  });

  final List<ActionCatalogSectionData> sections;
  final Set<String> selectedMods;
  final ValueChanged<String> onToggleMod;
  final String? anyKeyChar;
  final bool anyKeyListening;
  final FocusNode anyKeyFocus;
  final VoidCallback onAnyKeyTap;
  final KeyEventResult Function(FocusNode, KeyEvent) onAnyKeyEvent;
  final ValueChanged<String> onComboComplete;

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

    final anyLabel = anyKeyListening
        ? '…'
        : (anyKeyChar ?? '');

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
              child: Focus(
                focusNode: anyKeyFocus,
                onKeyEvent: onAnyKeyEvent,
                child: Material(
                  color: anyKeyListening
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                  child: InkWell(
                    onTap: onAnyKeyTap,
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 28,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            anyLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: anyKeyListening
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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
