import 'dart:ui' as ui;

import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer4_domain/models/macro.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _macroDelayUnitMs = 10;

/// Macro Settings page — macro list (left) + editor (right).
///
/// L3 owns only editor presentation and input capture. Device writes and
/// persistence stay behind [DeviceScope].
class HubMacroPanel extends StatefulWidget {
  const HubMacroPanel({super.key, this.scope, this.card, this.onChanged});

  final DeviceScope? scope;
  final DiscoveredCardState? card;
  final VoidCallback? onChanged;

  @override
  State<HubMacroPanel> createState() => _HubMacroPanelState();
}

class _HubMacroPanelState extends State<HubMacroPanel> {
  final FocusNode _recordFocus = FocusNode();
  final GlobalKey _stopRecordingKey = GlobalKey();
  final ScrollController _recordScrollController = ScrollController();
  final TextEditingController _loopController = TextEditingController(
    text: '1',
  );
  final List<MacroAction> _events = [];
  final Set<int> _pressedKeyCodes = <int>{};
  final Map<int, String> _pressedKeyLabels = <int, String>{};
  List<MacroDefinition> _macros = const [];
  MacroDraft? _draft;
  bool _recording = false;
  bool _calibrationMode = false;
  bool _loading = false;
  String? _error;
  int? _selectedSlot;
  int? _activePointerCode;
  String? _activePointerLabel;
  Stopwatch? _recordClock;
  int? _lastRecordEventUs;
  Stopwatch? _calibrationClock;
  int? _lastCalibrationEventUs;

  static const _macroDelayUnitUs = 10000;
  static const _minimumMakeDelay = 1;

  bool get _hasScope => widget.scope != null && widget.card != null;

  @override
  void initState() {
    super.initState();
    if (_hasScope) WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _recordFocus.dispose();
    _recordScrollController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final loaded = await widget.scope!.loadMacros(widget.card!);
      if (!mounted) return;
      setState(() {
        _macros = loaded;
        _loading = false;
        // Loading the list must not implicitly open the first macro. The
        // editor is entered only after an explicit list selection.
        _draft = null;
        _selectedSlot = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  MacroDraft _draftFrom(MacroDefinition macro) {
    _loopController.text = '${macro.loopTimes}';
    _selectedSlot = macro.slot;
    return MacroDraft(
      slot: macro.slot,
      name: macro.name.isEmpty ? 'M${macro.slot}' : macro.name,
      mode: macro.mode,
      loopTimes: macro.loopTimes,
      actions: macro.actions,
    );
  }

  void _openCreation() {
    final slot = _hasScope
        ? widget.scope!.nextMacroSlot(widget.card!)
        : _firstUnusedSlot();
    if (slot == null) {
      setState(() => _error = 'All 16 macro slots are already in use');
      return;
    }
    setState(() {
      _error = null;
      _calibrationMode = false;
      _selectedSlot = slot;
      _events.clear();
      _pressedKeyCodes.clear();
      _pressedKeyLabels.clear();
      _activePointerCode = null;
      _activePointerLabel = null;
      _loopController.text = '1';
      _draft = MacroDraft(
        slot: slot,
        name: 'M$slot',
        mode: MacroMode.loop,
        loopTimes: 1,
        actions: const [],
      );
    });
  }

  static bool _isTimingProbeMacro(MacroDefinition macro) =>
      macro.slot >= 5 &&
      macro.slot <= 8 &&
      macro.actions.any(
        (action) => action.keyCode >= 0x01 && action.keyCode <= 0x03,
      );

  int? _firstUnusedSlot() {
    final used = _macros.map((m) => m.slot).toSet();
    for (var slot = 1; slot <= MacroDefinition.maxSlots; slot++) {
      if (!used.contains(slot)) return slot;
    }
    return null;
  }

  void _selectMacro(MacroDefinition macro) {
    setState(() {
      _error = null;
      _calibrationMode = _isTimingProbeMacro(macro);
      _events
        ..clear()
        ..addAll(macro.actions);
      _pressedKeyCodes.clear();
      _pressedKeyLabels.clear();
      _activePointerCode = null;
      _activePointerLabel = null;
      _draft = _draftFrom(macro);
    });
  }

  /// Keep the editable domain draft aligned with the L3 event buffer.
  ///
  /// The event rows are the recorder's presentation state, while the draft is
  /// what Save validates and hands to L4. They must describe the same actions.
  void _syncDraftActions() {
    final draft = _draft;
    if (draft != null) {
      _draft = draft.copyWith(actions: _events);
    }
  }

  void _startRecording() {
    setState(() {
      _recording = true;
      // Recording an existing macro extends its current sequence. Reset is
      // the explicit action for replacing the sequence with the saved copy.
      _pressedKeyCodes.clear();
      _pressedKeyLabels.clear();
      _activePointerCode = null;
      _activePointerLabel = null;
      _error = null;
    });
    _recordClock = Stopwatch()..start();
    _lastRecordEventUs = null;
    if (_calibrationMode) {
      _calibrationClock = Stopwatch()..start();
      _lastCalibrationEventUs = null;
    }
    _recordFocus.requestFocus();
  }

  void _stopRecording() {
    _closeOpenActions();
    _normalizeSimpleKeyboardTaps();
    setState(() {
      _recording = false;
      _pressedKeyCodes.clear();
      _pressedKeyLabels.clear();
      _activePointerCode = null;
      _activePointerLabel = null;
    });
    _calibrationClock?.stop();
    _calibrationClock = null;
    _lastCalibrationEventUs = null;
    _recordClock?.stop();
    _recordClock = null;
    _lastRecordEventUs = null;
    _recordFocus.unfocus();
  }

  void _normalizeSimpleKeyboardTaps() {
    if (_events.isEmpty ||
        _events.any((action) => !_isSimpleKeyboardCode(action.keyCode))) {
      return;
    }

    final taps = <({int code, String? label, int downAt, int downDelay})>[];
    final open =
        <int, ({int code, String? label, int downAt, int downDelay})>{};
    var elapsed = 0;
    for (final action in _events) {
      if (action.isBreak) {
        if (open.remove(action.keyCode) == null) return;
      } else {
        if (open.containsKey(action.keyCode)) return;
        final tap = (
          code: action.keyCode,
          label: action.label,
          downAt: elapsed,
          downDelay: action.delay,
        );
        open[action.keyCode] = tap;
        taps.add(tap);
      }
      elapsed += action.delay;
    }
    if (open.isNotEmpty) return;

    final normalized = <MacroAction>[];
    for (var i = 0; i < taps.length; i++) {
      final tap = taps[i];
      final nextDownAt = i + 1 < taps.length ? taps[i + 1].downAt : tap.downAt;
      final gap = (nextDownAt - tap.downAt - tap.downDelay).clamp(0, 0x7F);
      normalized
        ..add(
          MacroAction(
            keyCode: tap.code,
            isBreak: false,
            delay: tap.downDelay == 0 ? _minimumMakeDelay : tap.downDelay,
            label: tap.label,
          ),
        )
        ..add(
          MacroAction(
            keyCode: tap.code,
            isBreak: true,
            delay: gap,
            label: tap.label,
          ),
        );
    }
    setState(() {
      _events
        ..clear()
        ..addAll(normalized);
      _syncDraftActions();
    });
  }

  static bool _isSimpleKeyboardCode(int code) =>
      code >= 0x04 && code <= 0xA4 && code < 0xE0;

  void _closeOpenActions() {
    for (final code in _pressedKeyCodes.toList(growable: false)) {
      final label = _pressedKeyLabels[code];
      if (label != null) {
        _appendRecordedAction(code: code, isBreak: true, label: label);
      }
    }
    final pointerCode = _activePointerCode;
    final pointerLabel = _activePointerLabel;
    if (pointerCode != null && pointerLabel != null) {
      _appendRecordedAction(
        code: pointerCode,
        isBreak: true,
        label: pointerLabel,
      );
    }
  }

  KeyEventResult _onRecordKeyEvent(FocusNode node, KeyEvent event) {
    if (!_recording) return KeyEventResult.ignored;
    final isBreak = switch (event) {
      KeyDownEvent() => false,
      KeyUpEvent() => true,
      _ => null,
    };
    if (isBreak == null) return KeyEventResult.handled;
    final label = _keyLabel(event);
    final code = label == null ? null : _keyCode(label);
    if (code == null) {
      setState(
        () => _error = 'Unsupported keyboard key: ${label ?? 'unknown'}',
      );
      return KeyEventResult.handled;
    }
    final clock = _calibrationClock;
    if (clock != null) {
      final elapsedUs = clock.elapsedMicroseconds;
      final deltaUs = _lastCalibrationEventUs == null
          ? null
          : elapsedUs - _lastCalibrationEventUs!;
      debugPrint(
        '[macro-calibration] ${isBreak ? 'up' : 'down'} $label '
        't=${elapsedUs}us${deltaUs == null ? '' : ' dt=${deltaUs}us'}',
      );
      _lastCalibrationEventUs = elapsedUs;
    }
    // Keep the physical key sequence authoritative. Flutter can deliver
    // repeats or a release after focus has changed; neither is a new macro
    // action and an orphan release must not appear before its press.
    if (!isBreak && !_pressedKeyCodes.add(code)) {
      return KeyEventResult.handled;
    }
    if (isBreak && !_pressedKeyCodes.contains(code)) {
      return KeyEventResult.handled;
    }
    _appendRecordedAction(code: code, isBreak: isBreak, label: label!);
    if (isBreak) {
      _pressedKeyCodes.remove(code);
      _pressedKeyLabels.remove(code);
    } else {
      _pressedKeyLabels[code] = label;
    }
    return KeyEventResult.handled;
  }

  void _appendRecordedAction({
    int? code,
    MacroAction? action,
    required bool isBreak,
    required String label,
  }) {
    final nowUs = _recordClock?.elapsedMicroseconds;
    setState(() {
      // The firmware delay is stored on the action that precedes the wait.
      // Capture the host interval here, then quantize it to the documented
      // 10 ms inline unit without sending host-clock milliseconds on-wire.
      if (_events.isNotEmpty && nowUs != null && _lastRecordEventUs != null) {
        final previous = _events.last;
        final elapsedUs = nowUs - _lastRecordEventUs!;
        final rounded = (elapsedUs / _macroDelayUnitUs).round();
        final rawDelay = rounded.clamp(0, 0x7F);
        _events[_events.length - 1] = previous.copyWith(
          delay: !previous.isBreak && rawDelay == 0
              ? _minimumMakeDelay
              : rawDelay,
        );
      }
      _events.add(
        action ??
            MacroAction(
              keyCode: code!,
              isBreak: isBreak,
              delay: 0,
              label: label,
            ),
      );
      _syncDraftActions();
    });
    _lastRecordEventUs = nowUs;
    _scrollRecordToEnd();
  }

  void _scrollRecordToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_recordScrollController.hasClients) return;
      final position = _recordScrollController.position;
      if (!position.hasContentDimensions) return;
      _recordScrollController.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    });
  }

  void _onPointerEvent(PointerEvent event) {
    if (!_recording || event.kind != ui.PointerDeviceKind.mouse) return;
    // why: the Stop button is part of this editor's Listener subtree; its
    // click controls recording and must not become a recorded mouse action.
    if (_isPointerOver(_stopRecordingKey, event.position)) return;
    // why: calibration is triggered by a physical mouse button. Ignore that
    // trigger's local pointer events so only the macro's generated output is
    // measured by the recorder.
    if (_calibrationMode) return;
    if (event is! PointerDownEvent && event is! PointerUpEvent) return;
    final button = event is PointerDownEvent
        ? switch (event.buttons) {
            1 => ('Left click', 0xF1),
            2 => ('Right click', 0xF2),
            4 => ('Middle click', 0xF3),
            8 => ('Mouse button 4', 0xF4),
            16 => ('Mouse button 5', 0xF5),
            _ => null,
          }
        : (_activePointerCode == null || _activePointerLabel == null
              ? null
              : (_activePointerLabel!, _activePointerCode!));
    if (button == null) return;
    final isBreak = event is PointerUpEvent;
    _appendRecordedAction(code: button.$2, isBreak: isBreak, label: button.$1);
    if (isBreak) {
      _activePointerCode = null;
      _activePointerLabel = null;
    } else {
      _activePointerCode = button.$2;
      _activePointerLabel = button.$1;
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (!_recording || event.kind != ui.PointerDeviceKind.mouse) return;
    // why: the Stop button is part of this editor's Listener subtree; a
    // scroll over it must not become a recorded macro action.
    if (_isPointerOver(_stopRecordingKey, event.position)) return;
    // why: calibration input is deliberately excluded from macro recording,
    // including wheel input received while calibration is active.
    if (_calibrationMode || event is! PointerScrollEvent) return;

    final verticalDelta = event.scrollDelta.dy;
    if (verticalDelta == 0) return;
    final isWheelUp = verticalDelta < 0;
    // Record each notch as a complete semantic wheel make+break pair. Layer 5
    // resolves the device wire value during macro encoding.
    final label = isWheelUp ? 'Wheel up' : 'Wheel down';
    final make = isWheelUp
        ? const MacroAction.wheelUp(isBreak: false, delay: 0, label: 'Wheel up')
        : const MacroAction.wheelDown(
            isBreak: false,
            delay: 0,
            label: 'Wheel down',
          );
    final breakAction = isWheelUp
        ? const MacroAction.wheelUp(isBreak: true, delay: 0, label: 'Wheel up')
        : const MacroAction.wheelDown(
            isBreak: true,
            delay: 0,
            label: 'Wheel down',
          );
    _appendRecordedAction(action: make, isBreak: false, label: label);
    _appendRecordedAction(action: breakAction, isBreak: true, label: label);
  }

  bool _isPointerOver(GlobalKey key, Offset position) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final bounds = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    return bounds.contains(position);
  }

  void _updateDraft(MacroDraft Function(MacroDraft) change) {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _draft = change(draft.copyWith(actions: _events)));
  }

  Future<void> _insertMouseButton() async {
    final selected = await showDialog<(String, int?)>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Insert Mouse Button'),
        children: [
          for (final item in const [
            ('Left click', 0xF1),
            ('Right click', 0xF2),
            ('Middle click', 0xF3),
            ('Mouse button 4', 0xF4),
            ('Mouse button 5', 0xF5),
            ('Wheel up', null),
            ('Wheel down', null),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item),
              child: Text(item.$1),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    MacroAction action({required bool isBreak}) {
      return switch (selected.$1) {
        'Wheel up' => MacroAction.wheelUp(
          isBreak: isBreak,
          delay: 0,
          label: selected.$1,
        ),
        'Wheel down' => MacroAction.wheelDown(
          isBreak: isBreak,
          delay: 0,
          label: selected.$1,
        ),
        _ => MacroAction(
          keyCode: selected.$2!,
          isBreak: isBreak,
          delay: 0,
          label: selected.$1,
        ),
      };
    }

    setState(() {
      _events
        ..add(action(isBreak: false))
        ..add(action(isBreak: true));
      _syncDraftActions();
    });
    _scrollRecordToEnd();
  }

  Future<void> _insertKeyboardKey() async {
    const choices = <String>[
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'Enter',
      'Esc',
      'Space',
      'Tab',
      'Shift',
      'Ctrl',
      'Alt',
      'F1',
      'F2',
      'F3',
      'Left',
      'Right',
      'Up',
      'Down',
    ];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Insert Keyboard Key'),
        children: [
          for (final label in choices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, label),
              child: Text(label),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final code = _keyCode(selected);
    if (code == null) return;
    setState(() {
      _events
        ..add(
          MacroAction(keyCode: code, isBreak: false, delay: 1, label: selected),
        )
        ..add(
          MacroAction(keyCode: code, isBreak: true, delay: 0, label: selected),
        );
      _syncDraftActions();
    });
    _scrollRecordToEnd();
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final loopTimes = int.tryParse(_loopController.text) ?? 0;
    final macro = draft.copyWith(loopTimes: loopTimes).toDefinition();
    final errors = validateMacro(macro);
    if (errors.isNotEmpty) {
      setState(() => _error = errors.join('\n'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_hasScope) {
        await widget.scope!.saveMacro(widget.card!, macro);
        _macros = widget.scope!.macrosFor(widget.card!);
      } else {
        final index = _macros.indexWhere((m) => m.slot == macro.slot);
        final next = [..._macros];
        if (index == -1) {
          next.add(macro);
        } else {
          next[index] = macro;
        }
        _macros = next;
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _draft = _draftFrom(macro);
      });
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _reset() {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _events
        ..clear()
        ..addAll(
          _macros.where((m) => m.slot == draft.slot).expand((m) => m.actions),
        );
      _syncDraftActions();
      _loopController.text =
          '${_macros.firstWhere((m) => m.slot == draft.slot, orElse: () => draft.toDefinition()).loopTimes}';
      _error = null;
    });
  }

  void _cancel() {
    final draft = _draft;
    MacroDefinition? saved;
    if (draft != null) {
      for (final macro in _macros) {
        if (macro.slot == draft.slot) {
          saved = macro;
          break;
        }
      }
    }
    setState(() {
      _recording = false;
      _calibrationMode = false;
      _pressedKeyCodes.clear();
      _pressedKeyLabels.clear();
      _activePointerCode = null;
      _activePointerLabel = null;
      if (saved != null) {
        // Discard only the current editor buffer; restore the selected slot's
        // last saved definition, not the first macro in the list.
        _events
          ..clear()
          ..addAll(saved.actions);
        _draft = _draftFrom(saved);
        _calibrationMode = _isTimingProbeMacro(saved);
      } else {
        // A newly-created macro has no persisted value to restore. Cancel
        // closes that draft without creating or deleting a saved macro.
        _events.clear();
        _draft = null;
        _selectedSlot = null;
      }
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _draft == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_draft == null) {
      if (_macros.isEmpty) {
        return _EmptyMacroState(onCreate: _openCreation);
      }
      return _buildUnselectedMacroState(context);
    }
    return _buildMacroEditor(context);
  }

  Widget _buildUnselectedMacroState(BuildContext context) {
    final buttonStyle = _macroOutlinedButtonStyle(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Text(
                  'Macro List',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: OutlinedButton(
                  onPressed: _openCreation,
                  style: buttonStyle,
                  child: const Text('New Macro'),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    for (final macro in _macros)
                      ListTile(
                        title: Text(
                          macro.name.isEmpty ? 'M${macro.slot}' : macro.name,
                        ),
                        selected: false,
                        onTap: () => _selectMacro(macro),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        const Expanded(flex: 4, child: _MacroSelectionEmptyState()),
      ],
    );
  }

  Widget _buildMacroEditor(BuildContext context) {
    final draft = _draft!;
    final buttonStyle = _macroOutlinedButtonStyle(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Text(
                  'Macro List',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: OutlinedButton(
                  onPressed: _openCreation,
                  style: buttonStyle,
                  child: const Text('New Macro'),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    for (final macro in _macros)
                      ListTile(
                        title: Text(
                          macro.name.isEmpty ? 'M${macro.slot}' : macro.name,
                        ),
                        selected: macro.slot == _selectedSlot,
                        onTap: () => _selectMacro(macro),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          flex: 4,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onPointerEvent,
            onPointerUp: _onPointerEvent,
            onPointerSignal: _onPointerSignal,
            child: Focus(
              focusNode: _recordFocus,
              onKeyEvent: _onRecordKeyEvent,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'M${draft.slot}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<MacroMode>(
                              initialValue: draft.mode,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Macro type',
                              ),
                              items: [
                                for (final mode in MacroMode.values)
                                  DropdownMenuItem(
                                    value: mode,
                                    child: Text(
                                      mode.label,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (mode) {
                                if (mode != null) {
                                  _updateDraft((d) => d.copyWith(mode: mode));
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _loopController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Loop count',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _recording ? null : _startRecording,
                          style: buttonStyle,
                          child: const Text('Start Recording'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          key: _stopRecordingKey,
                          onPressed: _recording ? _stopRecording : null,
                          style: buttonStyle,
                          child: const Text('Stop Recording'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Record'),
                          const SizedBox(height: 8),
                          if (_events.isEmpty)
                            Text(
                              _recording
                                  ? 'Recording — press keys…'
                                  : 'No events recorded',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 280),
                              child: ListView.builder(
                                controller: _recordScrollController,
                                shrinkWrap: true,
                                itemCount: _events.length,
                                itemBuilder: (context, i) => _MacroRow(
                                  action: _events[i],
                                  onDelete: () => setState(() {
                                    _events.removeAt(i);
                                    _syncDraftActions();
                                  }),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _insertMouseButton,
                      style: buttonStyle,
                      child: const Text('+ Insert Mouse Button'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _insertKeyboardKey,
                      style: buttonStyle,
                      child: const Text('+ Insert Keyboard Key'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _loading ? null : _reset,
                          style: buttonStyle,
                          child: const Text('Reset'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _loading ? null : _save,
                          style: buttonStyle,
                          child: const Text('Save'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _loading ? null : _cancel,
                          style: buttonStyle,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String? _keyLabel(KeyEvent event) {
    final raw = event.character;
    if (raw != null &&
        raw.isNotEmpty &&
        raw.characters.first.codeUnitAt(0) >= 0x20) {
      return raw.characters.first.toUpperCase();
    }
    final named = _logicalKeyLabels[event.logicalKey];
    if (named != null) return named;
    final logicalLabel = event.logicalKey.keyLabel.trim();
    if (logicalLabel.length == 1 && logicalLabel.codeUnitAt(0) >= 0x20) {
      return logicalLabel.toUpperCase();
    }
    return null;
  }

  static int? _keyCode(String label) {
    final normalized = label.toLowerCase();
    final entry = _keyCodes.entries.where(
      (e) => e.key.toLowerCase() == normalized,
    );
    return entry.isEmpty ? null : entry.first.value;
  }

  static final Map<String, int> _keyCodes = {
    for (var i = 0; i < 26; i++) String.fromCharCode(65 + i): 0x04 + i,
    '1': 0x1E,
    '2': 0x1F,
    '3': 0x20,
    '4': 0x21,
    '5': 0x22,
    '6': 0x23,
    '7': 0x24,
    '8': 0x25,
    '9': 0x26,
    '0': 0x27,
    'Enter': 0x28,
    'Esc': 0x29,
    'Backspace': 0x2A,
    'Tab': 0x2B,
    'Space': 0x2C,
    'F1': 0x3A,
    'F2': 0x3B,
    'F3': 0x3C,
    'F4': 0x3D,
    'F5': 0x3E,
    'F6': 0x3F,
    'F7': 0x40,
    'F8': 0x41,
    'F9': 0x42,
    'F10': 0x43,
    'F11': 0x44,
    'F12': 0x45,
    'Insert': 0x49,
    'Home': 0x4A,
    'Page Up': 0x4B,
    'Delete': 0x4C,
    'End': 0x4D,
    'Page Down': 0x4E,
    'Right': 0x4F,
    'Left': 0x50,
    'Down': 0x51,
    'Up': 0x52,
    'Ctrl': 0xE0,
    'Shift': 0xE1,
    'Alt': 0xE2,
  };

  static final Map<LogicalKeyboardKey, String> _logicalKeyLabels = {
    LogicalKeyboardKey.escape: 'Esc',
    LogicalKeyboardKey.enter: 'Enter',
    LogicalKeyboardKey.tab: 'Tab',
    LogicalKeyboardKey.backspace: 'Backspace',
    LogicalKeyboardKey.space: 'Space',
    LogicalKeyboardKey.arrowUp: 'Up',
    LogicalKeyboardKey.arrowDown: 'Down',
    LogicalKeyboardKey.arrowLeft: 'Left',
    LogicalKeyboardKey.arrowRight: 'Right',
    LogicalKeyboardKey.home: 'Home',
    LogicalKeyboardKey.end: 'End',
    LogicalKeyboardKey.pageUp: 'Page Up',
    LogicalKeyboardKey.pageDown: 'Page Down',
    LogicalKeyboardKey.insert: 'Insert',
    LogicalKeyboardKey.delete: 'Delete',
    LogicalKeyboardKey.shiftLeft: 'Shift',
    LogicalKeyboardKey.shiftRight: 'Shift',
    LogicalKeyboardKey.controlLeft: 'Ctrl',
    LogicalKeyboardKey.controlRight: 'Ctrl',
    LogicalKeyboardKey.altLeft: 'Alt',
    LogicalKeyboardKey.altRight: 'Alt',
    for (var i = 1; i <= 12; i++) LogicalKeyboardKey(0x00000000030 + i): 'F$i',
  };
}

ButtonStyle _macroOutlinedButtonStyle(BuildContext context) {
  final theme = Theme.of(context);
  return OutlinedButton.styleFrom(
    foregroundColor: theme.colorScheme.onSurface,
    side: BorderSide(color: theme.colorScheme.outline),
    shape: const StadiumBorder(),
  );
}

class _EmptyMacroState extends StatelessWidget {
  const _EmptyMacroState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('No macros configured'),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onCreate,
          style: _macroOutlinedButtonStyle(context),
          child: const Text('Create Macro'),
        ),
      ],
    ),
  );
}

class _MacroSelectionEmptyState extends StatelessWidget {
  const _MacroSelectionEmptyState();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Please select a shortcut to edit'));
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.action, required this.onDelete});
  final MacroAction action;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Text(action.label ?? '0x${action.keyCode.toRadixString(16)}'),
        Expanded(
          child: Center(child: Text(action.isBreak ? 'KeyUp' : 'KeyDown')),
        ),
        SizedBox(
          width: 64,
          child: Text(
            '${action.delay * _macroDelayUnitMs} ms',
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, size: 16),
        ),
      ],
    ),
  );
}
