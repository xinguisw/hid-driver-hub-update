import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer5_codec/button_action_catalog_map.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:driver_hub/i18n/catalog_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TapRegion group ID shared across button mapping panel and canvas
/// to allow collapsing when tapping outside the list.
const String hubButtonMappingTapRegionId = 'hub_button_mapping_tap_region';

/// Button Mapping right pane — action catalog.
///
/// L3 only. Tabs paint L4-packed catalogs (assets via L2). No catalog
/// ownership, no L5/HID. Row tap / Special combo = local UI only.
class HubButtonMappingPanel extends StatefulWidget {
  const HubButtonMappingPanel({
    super.key,
    this.selectedButtonId,
    this.buttons,
    this.mouseActionCatalog,
    this.keyboardActionCatalog,
    this.specialActionCatalog,
    this.macroSlots, // NEW: list of macros
    this.onActionSelected,
    this.onComboSelected,
    this.onCollapse,
    this.onMacroSelected, // NEW: callback for macro selection
  });

  final int? selectedButtonId;
  final List<ButtonData>? buttons;
  final List<ActionCatalogSectionData>? mouseActionCatalog;
  final List<ActionCatalogSectionData>? keyboardActionCatalog;
  final List<ActionCatalogSectionData>? specialActionCatalog;

  /// List of available macros (each with an ID and display name).
  final List<MacroSlot>? macroSlots;

  /// Called when user selects a catalog action (Mouse/Keyboard tabs).
  final ValueChanged<String>? onActionSelected;

  /// Called when user completes a special combo (modifiers + key).
  final void Function(List<String> modifierIds, String keyChar)?
  onComboSelected;

  /// Called to collapse the panel.
  final VoidCallback? onCollapse;

  /// Called when a macro is selected.
  final ValueChanged<String>? onMacroSelected;

  static const double width = 320;

  /// Product: combination shortcut allows at most two modifiers.
  static const int maxSpecialModifiers = 2;

  @override
  State<HubButtonMappingPanel> createState() => _HubButtonMappingPanelState();
}

/// Simple data class for a macro slot.
class MacroSlot {
  const MacroSlot({required this.id, required this.name});
  final String id;
  final String name;
}

class _HubButtonMappingPanelState extends State<HubButtonMappingPanel> {
  List<String> get _tabs => [
    t.mapping.mouse,
    t.mapping.keyboard,
    t.mapping.special,
    t.mapping.macro,
  ];

  int _tabIndex = 0;
  String? _selectedCatalogId;

  /// Special mods in selection order (FIFO when over max).
  final List<String> _specialModOrder = [];

  /// Any-key field: listening for one character, then disengages.
  bool _anyKeyListening = false;
  String? _anyKeyChar;
  final FocusNode _anyKeyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _syncWithSelectedButton();
  }

  @override
  void didUpdateWidget(HubButtonMappingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedButtonId != oldWidget.selectedButtonId ||
        widget.buttons != oldWidget.buttons) {
      _syncWithSelectedButton();
    }
  }

  void _syncWithSelectedButton() {
    final btnId = widget.selectedButtonId;
    if (btnId == null) return;

    final buttonList = widget.buttons;
    if (buttonList == null || buttonList.isEmpty) return;

    final button = buttonList.firstWhere(
      (b) => b.id == btnId,
      orElse: () => buttonList.first,
    );

    final info = ButtonActionCatalogMap.slotToCatalogInfo(
      button.action ?? 0,
      button.param1 ?? 0,
      button.param2 ?? 0,
      button.param3 ?? 0,
    );

    if (info != null) {
      setState(() {
        _tabIndex = info.tabIndex;
        _selectedCatalogId = info.catalogId;
        _specialModOrder.clear();
        _specialModOrder.addAll(info.modifierIds);
        _anyKeyChar = info.keyChar;
        _anyKeyListening = false;
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
    });
    _anyKeyFocus.requestFocus();
    // why: click again to change — wait for a new key; keep old until captured
  }

  KeyEventResult _onAnyKeyEvent(FocusNode node, KeyEvent event) {
    if (!_anyKeyListening) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Extract character from event
    String? ch;
    final raw = event.character;
    if (raw != null &&
        raw.isNotEmpty &&
        raw.characters.first.codeUnitAt(0) > 0x20 &&
        event.logicalKey != LogicalKeyboardKey.space) {
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
    return TapRegion(
      groupId: hubButtonMappingTapRegionId,
      onTapOutside: (_) => widget.onCollapse?.call(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Segmented Pill Tab Bar (Reference UI style)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
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
                  ),
                ),
                const SizedBox(height: 4),

                // Catalog List Body
                Expanded(
                  child: ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.15,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.04, 0.0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                      child: KeyedSubtree(
                        key: ValueKey<Object?>(
                          '${_tabIndex}_${widget.selectedButtonId}',
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
                              if (_specialModOrder.isNotEmpty) {
                                widget.onComboSelected?.call(
                                  List<String>.from(_specialModOrder),
                                  keyChar,
                                );
                              }
                            },
                          ),
                          3 => _MacroCatalogBody(
                            macroSlots: widget.macroSlots ?? const [],
                            selectedId: _selectedCatalogId,
                            onSelect: (id) {
                              setState(() => _selectedCatalogId = id);
                              widget.onMacroSelected?.call(id);
                            },
                          ),
                          _ => const SizedBox.expand(),
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Collapse handle on the left edge
            if (widget.onCollapse != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    elevation: 2,
                    shadowColor: Colors.black26,
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: InkWell(
                      onTap: widget.onCollapse,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      child: Container(
                        width: 18,
                        height: 38,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in sections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                CatalogLocalization.localizeSectionTitle(section.title, t),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            for (final item in section.items)
              _CatalogItemTile(
                key: ValueKey(item.id),
                item: item,
                selected: item.id == selectedId,
                onSelect: () => onSelect(item.id),
              ),
          ],
        ],
      ),
    );
  }
}

class _CatalogItemTile extends StatefulWidget {
  const _CatalogItemTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onSelect,
  });

  final ActionCatalogItemData item;
  final bool selected;
  final VoidCallback onSelect;

  @override
  State<_CatalogItemTile> createState() => _CatalogItemTileState();
}

class _CatalogItemTileState extends State<_CatalogItemTile> {
  @override
  void initState() {
    super.initState();
    if (widget.selected) {
      _scrollToSelf();
    }
  }

  @override
  void didUpdateWidget(_CatalogItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _scrollToSelf();
    }
  }

  void _scrollToSelf() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.3,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 2, 12, 2),
      child: Material(
        color: widget.selected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: widget.onSelect,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              CatalogLocalization.localizeItemLabel(
                widget.item.id,
                widget.item.label,
                t,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: widget.selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(
            CatalogLocalization.localizeSectionTitle(section.title, t),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 6, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  t.mapping.modifierKey,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
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
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          onTap: () => onToggleMod(m.id),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              CatalogLocalization.localizeItemLabel(
                                m.id,
                                m.label,
                                t,
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: selectedMods.contains(m.id)
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                fontSize: 12,
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
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 6, 16, 8),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  anyKey != null
                      ? CatalogLocalization.localizeItemLabel(
                          anyKey.id,
                          anyKey.label,
                          t,
                        )
                      : t.mapping.anyKey,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
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
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: onAnyKeyTap,
                      canRequestFocus: false,
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 32,
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
                                fontSize: 12,
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
        ),
      ],
    );
  }
}

/// Macro tab — list of available macros with selection.
class _MacroCatalogBody extends StatelessWidget {
  const _MacroCatalogBody({
    required this.macroSlots,
    required this.selectedId,
    required this.onSelect,
  });

  final List<MacroSlot> macroSlots;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (macroSlots.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 16, top: 4),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              t.sidebar.macroSetting,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 24, 16),
            child: Column(
              children: [
                Icon(
                  Icons.extension_outlined,
                  size: 32,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.macro.noMacrosConfigured,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.macro.noMacrosConfiguredDesc,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(
            'Macro Setting',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ),
        for (final slot in macroSlots)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 2, 12, 2),
            child: Material(
              color: slot.id == selectedId
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () => onSelect(slot.id),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    slot.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: slot.id == selectedId
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      fontWeight: slot.id == selectedId
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
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
    final isDark = theme.brightness == Brightness.dark;

    final selectedBg = isDark ? Colors.white : Colors.black;
    final selectedFg = isDark ? Colors.black : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: selected ? selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? selectedFg
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
