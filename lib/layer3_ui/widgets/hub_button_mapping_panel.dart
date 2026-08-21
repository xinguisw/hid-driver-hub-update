import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer4_domain/models/macro.dart';
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
    this.macroSlots = const [],
    this.onMacroSelected,
  });

  final int? selectedButtonId;
  final List<ActionCatalogSectionData>? mouseActionCatalog;
  final List<ActionCatalogSectionData>? keyboardActionCatalog;
  final List<ActionCatalogSectionData>? specialActionCatalog;

  /// Called when user selects a catalog action (Mouse/Keyboard tabs).
  final ValueChanged<String>? onActionSelected;

  /// Called when user completes a special combo (modifiers + key).
  final void Function(List<String> modifierIds, String keyChar)?
  onComboSelected;
  final List<MacroDefinition> macroSlots;
  final ValueChanged<int>? onMacroSelected;

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
  void didUpdateWidget(HubButtonMappingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedButtonId != widget.selectedButtonId) {
      setState(() {
        _specialModOrder.clear();
        _anyKeyListening = false;
        _anyKeyChar = null;
        _selectedCatalogId = null;
      });
    }
  }

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
      } else {
        // At max: drop oldest so the new pick can light; always ≤ 2 selected.
        if (_specialModOrder.length >=
            HubButtonMappingPanel.maxSpecialModifiers) {
          _specialModOrder.removeAt(0);
        }
        _specialModOrder.add(id);
      }
      if (_anyKeyChar != null) {
        widget.onComboSelected?.call(
          List<String>.from(_specialModOrder),
          _anyKeyChar!,
        );
      }
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

    String? ch = _logicalKeyToChar[event.logicalKey];
    if (ch == null) {
      final raw = event.character;
      if (raw != null &&
          raw.isNotEmpty &&
          raw.characters.first.codeUnitAt(0) > 0x20) {
        ch = raw.characters.first;
      }
    }

    if (ch == null) return KeyEventResult.ignored;

    setState(() {
      _anyKeyChar = ch;
      _anyKeyListening = false;
    });

    // Dispatch key combo / single key choice flexibly (modifiers optional)
    widget.onComboSelected?.call(List<String>.from(_specialModOrder), ch);

    return KeyEventResult.handled;
  }

  /// Map logical keys to their character representations for special keys.
  static final Map<LogicalKeyboardKey, String> _logicalKeyToChar = {
    LogicalKeyboardKey.escape: 'Esc',
    LogicalKeyboardKey.enter: 'Enter',
    LogicalKeyboardKey.tab: 'Tab',
    LogicalKeyboardKey.backspace: 'Backspace',
    LogicalKeyboardKey.space: 'Space',
    LogicalKeyboardKey.capsLock: 'Caps Lock',
    LogicalKeyboardKey.numLock: 'Num Lock',
    LogicalKeyboardKey.scrollLock: 'Scroll Lock',
    LogicalKeyboardKey.printScreen: 'Print Screen',
    LogicalKeyboardKey.pause: 'Pause',
    LogicalKeyboardKey.contextMenu: 'Menu',
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
    LogicalKeyboardKey.numpad0: '0',
    LogicalKeyboardKey.numpad1: '1',
    LogicalKeyboardKey.numpad2: '2',
    LogicalKeyboardKey.numpad3: '3',
    LogicalKeyboardKey.numpad4: '4',
    LogicalKeyboardKey.numpad5: '5',
    LogicalKeyboardKey.numpad6: '6',
    LogicalKeyboardKey.numpad7: '7',
    LogicalKeyboardKey.numpad8: '8',
    LogicalKeyboardKey.numpad9: '9',
    LogicalKeyboardKey.numpadAdd: '+',
    LogicalKeyboardKey.numpadSubtract: '-',
    LogicalKeyboardKey.numpadMultiply: '*',
    LogicalKeyboardKey.numpadDivide: '/',
    LogicalKeyboardKey.numpadDecimal: '.',
    LogicalKeyboardKey.numpadEnter: 'Enter',
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
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
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
                    widget.onComboSelected?.call(
                      List<String>.from(_specialModOrder),
                      keyChar,
                    );
                  },
                ),
                _ => _MacroCatalogBody(
                  macros: widget.macroSlots,
                  selectedSlot: _selectedCatalogId == null
                      ? null
                      : int.tryParse(
                          _selectedCatalogId!.replaceFirst('macro.', ''),
                        ),
                  onSelect: (slot) {
                    setState(() => _selectedCatalogId = 'macro.$slot');
                    widget.onMacroSelected?.call(slot);
                  },
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroCatalogBody extends StatelessWidget {
  const _MacroCatalogBody({
    required this.macros,
    required this.selectedSlot,
    required this.onSelect,
  });

  final List<MacroDefinition> macros;
  final int? selectedSlot;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (macros.isEmpty) {
      return const Center(child: Text('No macros configured'));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Text('Macro'),
        ),
        for (final macro in macros)
          Material(
            color: macro.slot == selectedSlot
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(macro.slot),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  macro.name.isEmpty ? 'M${macro.slot}' : macro.name,
                  style: TextStyle(
                    color: macro.slot == selectedSlot
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
      ],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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

    final anyLabel = anyKeyListening ? '…' : (anyKeyChar ?? '');

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
