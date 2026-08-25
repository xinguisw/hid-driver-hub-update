import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer4_domain/models/macro.dart';
import 'package:driver_hub/layer5_codec/codecs/keyvalue_table.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:driver_hub/i18n/catalog_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _macroDelayUnitMs = 10;

enum MacroDelayMode { recorded, fixed }

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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fixedDelayController = TextEditingController(
    text: '10',
  );
  MacroDelayMode _delayMode = MacroDelayMode.recorded;
  final List<MacroAction> _events = [];
  final Set<int> _pressedKeyCodes = <int>{};
  final Map<int, String> _pressedKeyLabels = <int, String>{};
  List<MacroDefinition> _macros = const [];
  MacroDraft? _draft;
  bool _recording = false;
  bool _calibrationMode = false;
  bool _loading = true;
  String? _error;
  int? _selectedSlot;
  int? _activePointerCode;
  String? _activePointerLabel;
  Stopwatch? _recordClock;
  int? _lastRecordEventUs;
  Stopwatch? _calibrationClock;
  int? _lastCalibrationEventUs;
  Timer? _toastTimer;
  String? _toastMessage;
  bool _toastIsSuccess = true;

  static const _macroDelayUnitUs = 10000;
  static const _minimumMakeDelay = 1;

  bool get _hasScope => widget.scope != null && widget.card != null;



  @override
  void initState() {
    super.initState();
    if (_hasScope) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    } else {
      _loading = false;
    }
  }

  @override
  void didUpdateWidget(HubMacroPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card?.devId != widget.card?.devId) {
      if (_hasScope) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _load());
      }
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _recordFocus.dispose();
    _recordScrollController.dispose();
    _loopController.dispose();
    _nameController.dispose();
    _fixedDelayController.dispose();
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
    final macroName = macro.name.isEmpty ? 'M${macro.slot}' : macro.name;
    _nameController.text = macroName;
    _selectedSlot = macro.slot;
    return MacroDraft(
      slot: macro.slot,
      name: macroName,
      mode: macro.mode,
      loopTimes: macro.loopTimes,
      actions: macro.actions,
    );
  }

  void _openCreation() {
    if (_recording) return;
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
      _delayMode = MacroDelayMode.recorded;
      _fixedDelayController.text = '10';
      _selectedSlot = slot;
      _events.clear();
      _pressedKeyCodes.clear();
      _pressedKeyLabels.clear();
      _activePointerCode = null;
      _activePointerLabel = null;
      _loopController.text = '1';
      _nameController.text = 'M$slot';
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
    if (_recording) return;
    setState(() {
      _error = null;
      _calibrationMode = _isTimingProbeMacro(macro);
      _delayMode = MacroDelayMode.recorded;
      _fixedDelayController.text = '10';
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
    if (_isConsumerOrMediaKey(event)) {
      setState(
        () => _error = 'Consumer and multimedia keys cannot be recorded',
      );
      return KeyEventResult.handled;
    }
    final resolved = _resolveKeyEvent(event);
    if (resolved == null) {
      final label = _keyLabel(event) ?? event.logicalKey.keyLabel;
      setState(
        () => _error =
            'Unsupported keyboard key: ${label.isEmpty ? 'unknown' : label}',
      );
      return KeyEventResult.handled;
    }
    final code = resolved.$1;
    final label = resolved.$2;
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
    _appendRecordedAction(code: code, isBreak: isBreak, label: label);
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
        int rawDelay;
        if (_delayMode == MacroDelayMode.fixed) {
          final fixedMs = int.tryParse(_fixedDelayController.text) ?? 10;
          rawDelay = (fixedMs / _macroDelayUnitMs).round().clamp(0, 10);
        } else {
          final elapsedUs = nowUs - _lastRecordEventUs!;
          final rounded = (elapsedUs / _macroDelayUnitUs).round();
          rawDelay = rounded.clamp(0, 0x7F);
        }
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
            1 => ('Left Button', 0xC1),
            2 => ('Right Button', 0xC2),
            4 => ('Middle Button', 0xC3),
            8 => ('Backward Button', 0xC5),
            16 => ('Forward Button', 0xC4),
            32 => ('Tilt Left', 0xB9),
            64 => ('Tilt Right', 0xB8),
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
    final horizontalDelta = event.scrollDelta.dx;

    if (verticalDelta != 0) {
      final isWheelUp = verticalDelta < 0;
      // Record each notch as a single semantic wheel action. Mouse wheel is a
      // directional impulse event rather than a key down/up pair.
      final label = isWheelUp ? 'Wheel Up' : 'Wheel Down';
      final action = isWheelUp
          ? const MacroAction.wheelUp(
              isBreak: false,
              delay: 0,
              label: 'Wheel Up',
            )
          : const MacroAction.wheelDown(
              isBreak: false,
              delay: 0,
              label: 'Wheel Down',
            );
      _appendRecordedAction(action: action, isBreak: false, label: label);
    }

    if (horizontalDelta != 0) {
      final isTiltLeft = horizontalDelta < 0;
      final label = isTiltLeft ? 'Tilt Left' : 'Tilt Right';
      final action = isTiltLeft
          ? const MacroAction.tiltLeft(
              isBreak: false,
              delay: 0,
              label: 'Tilt Left',
            )
          : const MacroAction.tiltRight(
              isBreak: false,
              delay: 0,
              label: 'Tilt Right',
            );
      _appendRecordedAction(action: action, isBreak: false, label: label);
    }
  }

  bool _isPointerOver(GlobalKey key, Offset position) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final bounds = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    return bounds.contains(position);
  }

  void _applyFixedDelayToEvents() {
    if (_delayMode != MacroDelayMode.fixed || _events.length <= 1) return;
    final fixedMs = int.tryParse(_fixedDelayController.text) ?? 10;
    final rawDelay = (fixedMs / _macroDelayUnitMs).round().clamp(0, 10);
    for (var i = 0; i < _events.length - 1; i++) {
      final act = _events[i];
      _events[i] = act.copyWith(
        delay: !act.isBreak && rawDelay == 0 ? _minimumMakeDelay : rawDelay,
      );
    }
    _syncDraftActions();
  }

  bool _validateFixedDelay(String value) {
    if (_delayMode != MacroDelayMode.fixed) return true;
    final val = int.tryParse(value);
    if (val == null || val < 0 || val > 100) {
      setState(() {
        _error = 'Fixed delay must be between 0 and 100 ms';
      });
      return false;
    } else if (_error != null &&
        _error!.startsWith('Fixed delay must be between')) {
      setState(() {
        _error = null;
      });
    }
    return true;
  }

  void _updateDraft(MacroDraft Function(MacroDraft) change) {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _draft = change(draft.copyWith(actions: _events)));
  }

  void _showToast({required String message, required bool isSuccess}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastIsSuccess = isSuccess;
    });
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _toastMessage = null;
      });
    });
  }

  Future<void> _save() async {
    if (_recording) return;
    final draft = _draft;
    if (draft == null) return;
    if (_delayMode == MacroDelayMode.fixed) {
      final fixedMs = int.tryParse(_fixedDelayController.text);
      if (fixedMs == null || fixedMs < 0 || fixedMs > 100) {
        setState(() => _error = 'Fixed delay must be between 0 and 100 ms');
        _showToast(message: t.macro.savedFailed, isSuccess: false);
        return;
      }
    }
    final loopTimes = int.tryParse(_loopController.text) ?? 0;
    final nameInput = _nameController.text.trim();
    final macroName = nameInput.isEmpty ? 'M${draft.slot}' : nameInput;
    final macro = draft
        .copyWith(name: macroName, loopTimes: loopTimes)
        .toDefinition();
    final errors = validateMacro(macro);
    if (errors.isNotEmpty) {
      setState(() => _error = errors.join('\n'));
      _showToast(message: t.macro.savedFailed, isSuccess: false);
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
        _draft = null;
        _events.clear();
        _error = null;
      });
      _showToast(message: t.macro.savedSuccess, isSuccess: true);
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Macro save failed: ${e is FormatException ? e.message : 'device error or timeout'}';
      });
      _showToast(message: t.macro.savedFailed, isSuccess: false);
    }
  }

  Future<void> _deleteMacro(MacroDefinition macro) async {
    if (_recording) return;
    final devName = widget.card?.displayName ?? 'standalone';
    debugPrint('[hub] $devName: deleting macro M${macro.slot} (${macro.name})');
    setState(() => _loading = true);
    try {
      if (_hasScope) {
        await widget.scope!.deleteMacro(widget.card!, macro.slot);
        _macros = widget.scope!.macrosFor(widget.card!);
      } else {
        _macros = List.unmodifiable(_macros.where((m) => m.slot != macro.slot));
      }
      debugPrint('[hub] $devName: deleted macro M${macro.slot} successfully');
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_selectedSlot == macro.slot) {
          _draft = null;
          _selectedSlot = null;
          _events.clear();
        }
      });
      widget.onChanged?.call();
    } catch (e) {
      debugPrint('[hub] $devName: macro deletion failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _reset() {
    if (_draft == null) return;
    setState(() {
      _recording = false;
      _calibrationMode = false;
      _events.clear();
      _pressedKeyCodes.clear();
      _pressedKeyLabels.clear();
      _activePointerCode = null;
      _activePointerLabel = null;
      _syncDraftActions();
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
    Widget content;
    if (_loading && _draft == null) {
      content = const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    } else if (_draft == null) {
      if (_macros.isEmpty) {
        content = _EmptyMacroState(
          key: const ValueKey('empty_list'),
          onCreate: _openCreation,
        );
      } else {
        content = _buildUnselectedMacroState(context);
      }
    } else {
      content = _buildMacroEditor(context);
    }

    return Stack(
      children: [
        content,
        if (_toastMessage != null)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: MacroToast(
                  message: _toastMessage!,
                  isSuccess: _toastIsSuccess,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUnselectedMacroState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final renderW = math.max(480.0, constraints.maxWidth);
        final listWidth = (renderW * 0.32).clamp(160.0, 220.0);
        final content = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: listWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.extension_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            t.macro.macroList,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          tooltip: t.macro.newMacro,
                          onPressed: _recording ? null : _openCreation,
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _macros.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final macro = _macros[index];
                        final displayName = macro.name.isEmpty
                            ? 'M${macro.slot}'
                            : macro.name;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _recording
                                ? null
                                : () => _selectMacro(macro),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? theme.colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.08),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.keyboard_command_key_rounded,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                    ),
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                    tooltip: t.macro.deleteMacro,
                                    onPressed: _recording
                                        ? null
                                        : () => _deleteMacro(macro),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              flex: 4,
              child: _MacroSelectionEmptyState(onNewMacro: _openCreation),
            ),
          ],
        );

        if (constraints.maxWidth < 480) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 480,
              height: constraints.maxHeight,
              child: content,
            ),
          );
        }
        return content;
      },
    );
  }

  Widget _buildMacroEditor(BuildContext context) {
    final draft = _draft!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final buttonStyle = _macroOutlinedButtonStyle(context);
    final cardBorderColor = (isDark ? Colors.white : Colors.black).withValues(
      alpha: 0.45,
    );
    final cardBoxDecoration = BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: cardBorderColor, width: 1.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final renderW = math.max(480.0, constraints.maxWidth);
        final listWidth = (renderW * 0.32).clamp(160.0, 220.0);
        final content = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: listWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.extension_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            t.macro.macroList,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          tooltip: t.macro.newMacro,
                          onPressed: _recording ? null : _openCreation,
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _macros.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final macro = _macros[index];
                        final isSelected = macro.slot == draft.slot;
                        final displayName = macro.name.isEmpty
                            ? 'M${macro.slot}'
                            : macro.name;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _recording
                                ? null
                                : () => _selectMacro(macro),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.12,
                                      )
                                    : (isDark
                                          ? theme.colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.2)
                                          : Colors.grey.withValues(alpha: 0.05)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : (isDark
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : Colors.black.withValues(
                                                alpha: 0.08,
                                              )),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.keyboard_command_key_rounded,
                                    size: 16,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                    ),
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                    tooltip: t.macro.deleteMacro,
                                    onPressed: _recording
                                        ? null
                                        : () => _deleteMacro(macro),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  labelText: t.macro.macroName,
                                  hintText: 'M${draft.slot}',
                                  hintStyle: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  _updateDraft((d) => d.copyWith(name: value));
                                  if (value.length >
                                      MacroDefinition.maxNameLength) {
                                    setState(() {
                                      _error =
                                          'Macro name must not exceed ${MacroDefinition.maxNameLength} characters';
                                    });
                                  } else if (_error != null &&
                                      _error!.startsWith(
                                        'Macro name must not exceed',
                                      )) {
                                    setState(() {
                                      _error = null;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              tooltip: t.macro.deleteMacro,
                              onPressed: () {
                                final existing = _macros.firstWhere(
                                  (m) => m.slot == draft.slot,
                                  orElse: () => draft.toDefinition(),
                                );
                                _deleteMacro(existing);
                              },
                            ),
                          ],
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0x33F87171)
                                  : const Color(0xFFFDE8E8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFF87171)
                                    : const Color(0xFFF8B4B4),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: isDark
                                      ? const Color(0xFFFCA5A5)
                                      : const Color(0xFF9B1C1C),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFFCA5A5)
                                          : const Color(0xFF9B1C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: cardBoxDecoration,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 16,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 140,
                                  maxWidth: 240,
                                ),
                                child: DropdownButtonFormField<MacroMode>(
                                  initialValue: draft.mode,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: t.macro.macroType,
                                  ),
                                  items: [
                                    for (final mode in MacroMode.values)
                                      DropdownMenuItem(
                                        value: mode,
                                        child: Text(
                                          mode == MacroMode.loop
                                              ? t.macro.modes.loop
                                              : (mode == MacroMode.stopOnAnyKey
                                                  ? t.macro.modes.stopOnAnyKey
                                                  : t.macro.modes.playOnHold),
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
                              SizedBox(
                                width: 140,
                                child: TextField(
                                  controller: _loopController,
                                  enabled: draft.mode == MacroMode.loop,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: t.macro.loopCount,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: cardBoxDecoration,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.macro.keyDelayMode,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _SelectableChip(
                                        label: t.macro.recordedDelay,
                                        selected:
                                            _delayMode == MacroDelayMode.recorded,
                                        onTap: () {
                                          setState(() {
                                            _delayMode = MacroDelayMode.recorded;
                                            if (_error != null &&
                                                _error!.startsWith(
                                                  'Fixed delay must be between',
                                                )) {
                                              _error = null;
                                            }
                                          });
                                        },
                                      ),
                                      _SelectableChip(
                                        label: t.macro.fixedDelay,
                                        selected:
                                            _delayMode == MacroDelayMode.fixed,
                                        onTap: () {
                                          setState(() {
                                            _delayMode = MacroDelayMode.fixed;
                                            _applyFixedDelayToEvents();
                                            _validateFixedDelay(
                                              _fixedDelayController.text,
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 140,
                                child: TextField(
                                  controller: _fixedDelayController,
                                  enabled: _delayMode == MacroDelayMode.fixed,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: t.macro.fixedDelayMs,
                                    hintText: '10',
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _validateFixedDelay(val);
                                      if (_delayMode == MacroDelayMode.fixed) {
                                        _applyFixedDelayToEvents();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: _recording ? null : _startRecording,
                                style: buttonStyle,
                                child: Text(t.macro.startRecording),
                              ),
                              OutlinedButton(
                                key: _stopRecordingKey,
                                onPressed: _recording ? _stopRecording : null,
                                style: buttonStyle,
                                child: Text(t.macro.stopRecording),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: cardBoxDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.macro.record),
                              const SizedBox(height: 8),
                              if (_events.isEmpty)
                                Text(
                                  _recording
                                      ? t.macro.recordingInProgress
                                      : t.macro.noEventsRecorded,
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
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: _loading || _recording ? null : _reset,
                                style: _macroOutlinedButtonStyle(context),
                                child: Text(t.macro.reset),
                              ),
                              OutlinedButton(
                                onPressed: _loading || _recording ? null : _save,
                                style: _macroOutlinedButtonStyle(context),
                                child: Text(t.macro.save),
                              ),
                              OutlinedButton(
                                onPressed: _loading ? null : _cancel,
                                style: _macroOutlinedButtonStyle(context),
                                child: Text(t.macro.cancel),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

        if (constraints.maxWidth < 480) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 480,
              height: constraints.maxHeight,
              child: content,
            ),
          );
        }
        return content;
      },
    );
  }

  static bool _isConsumerOrMediaKey(KeyEvent event) {
    final usagePage = (event.physicalKey.usbHidUsage >> 16) & 0xFFFF;
    if (usagePage == 0x0C) return true;
    if (usagePage == 0x01) {
      final code = event.physicalKey.usbHidUsage & 0xFFFF;
      if (code == 0x81 || code == 0x82 || code == 0x83) return true;
    }
    final logical = event.logicalKey;
    if (_consumerLogicalKeys.contains(logical)) return true;
    return false;
  }

  static (int, String)? _resolveKeyEvent(KeyEvent event) {
    if (_isConsumerOrMediaKey(event)) return null;

    final phyUsage = event.physicalKey.usbHidUsage;
    if (phyUsage != 0) {
      final usagePage = (phyUsage >> 16) & 0xFFFF;
      final usageId = phyUsage & 0xFFFF;
      if (usagePage == 0x07 &&
          ((usageId >= 0x04 && usageId <= 0x9F) ||
              (usageId >= 0xE0 && usageId <= 0xE7))) {
        final label =
            _logicalKeyLabels[event.logicalKey] ??
            _keyLabelFromChar(event) ??
            _keyCodesToLabel[usageId] ??
            KeyvalueTable().keyValueToLabel(usageId);
        return (usageId, label);
      }
    }

    final mapped = _logicalKeyToCodeAndLabel[event.logicalKey];
    if (mapped != null) return mapped;

    final charLabel = _keyLabelFromChar(event);
    if (charLabel != null) {
      final code = _keyCode(charLabel);
      if (code != null &&
          ((code >= 0x04 && code <= 0x9F) || (code >= 0xE0 && code <= 0xE7))) {
        return (code, charLabel);
      }
    }

    final keyLabel = event.logicalKey.keyLabel.trim();
    if (keyLabel.isNotEmpty) {
      final code = _keyCode(keyLabel);
      if (code != null &&
          ((code >= 0x04 && code <= 0x9F) || (code >= 0xE0 && code <= 0xE7))) {
        final label = _keyCodesToLabel[code] ?? keyLabel;
        return (code, label);
      }
    }

    return null;
  }

  static String? _keyLabelFromChar(KeyEvent event) {
    final raw = event.character;
    if (raw != null &&
        raw.isNotEmpty &&
        raw.characters.first.codeUnitAt(0) >= 0x20) {
      return raw.characters.first.toUpperCase();
    }
    return null;
  }

  static String? _keyLabel(KeyEvent event) {
    final resolved = _resolveKeyEvent(event);
    if (resolved != null) return resolved.$2;
    return _keyLabelFromChar(event) ??
        _logicalKeyLabels[event.logicalKey] ??
        (event.logicalKey.keyLabel.trim().isEmpty
            ? null
            : event.logicalKey.keyLabel.trim());
  }

  static int? _keyCode(String label) {
    final normalized = label.toLowerCase();
    final entry = _keyCodes.entries.where(
      (e) => e.key.toLowerCase() == normalized,
    );
    return entry.isEmpty ? null : entry.first.value;
  }

  static final Set<LogicalKeyboardKey> _consumerLogicalKeys = {
    LogicalKeyboardKey.audioVolumeDown,
    LogicalKeyboardKey.audioVolumeUp,
    LogicalKeyboardKey.audioVolumeMute,
    LogicalKeyboardKey.mediaPlay,
    LogicalKeyboardKey.mediaPause,
    LogicalKeyboardKey.mediaPlayPause,
    LogicalKeyboardKey.mediaStop,
    LogicalKeyboardKey.mediaTrackNext,
    LogicalKeyboardKey.mediaTrackPrevious,
    LogicalKeyboardKey.mediaRecord,
    LogicalKeyboardKey.mediaFastForward,
    LogicalKeyboardKey.mediaRewind,
    LogicalKeyboardKey.eject,
    LogicalKeyboardKey.browserSearch,
    LogicalKeyboardKey.browserHome,
    LogicalKeyboardKey.browserBack,
    LogicalKeyboardKey.browserForward,
    LogicalKeyboardKey.browserStop,
    LogicalKeyboardKey.browserRefresh,
    LogicalKeyboardKey.browserFavorites,
    LogicalKeyboardKey.launchMail,
    LogicalKeyboardKey.launchControlPanel,
    LogicalKeyboardKey.launchCalendar,
    LogicalKeyboardKey.launchContacts,
    LogicalKeyboardKey.launchMusicPlayer,
    LogicalKeyboardKey.launchAssistant,
    LogicalKeyboardKey.power,
    LogicalKeyboardKey.sleep,
    LogicalKeyboardKey.wakeUp,
  };

  static final Map<LogicalKeyboardKey, (int, String)>
  _logicalKeyToCodeAndLabel = {
    // Letters
    LogicalKeyboardKey.keyA: (0x04, 'A'),
    LogicalKeyboardKey.keyB: (0x05, 'B'),
    LogicalKeyboardKey.keyC: (0x06, 'C'),
    LogicalKeyboardKey.keyD: (0x07, 'D'),
    LogicalKeyboardKey.keyE: (0x08, 'E'),
    LogicalKeyboardKey.keyF: (0x09, 'F'),
    LogicalKeyboardKey.keyG: (0x0A, 'G'),
    LogicalKeyboardKey.keyH: (0x0B, 'H'),
    LogicalKeyboardKey.keyI: (0x0C, 'I'),
    LogicalKeyboardKey.keyJ: (0x0D, 'J'),
    LogicalKeyboardKey.keyK: (0x0E, 'K'),
    LogicalKeyboardKey.keyL: (0x0F, 'L'),
    LogicalKeyboardKey.keyM: (0x10, 'M'),
    LogicalKeyboardKey.keyN: (0x11, 'N'),
    LogicalKeyboardKey.keyO: (0x12, 'O'),
    LogicalKeyboardKey.keyP: (0x13, 'P'),
    LogicalKeyboardKey.keyQ: (0x14, 'Q'),
    LogicalKeyboardKey.keyR: (0x15, 'R'),
    LogicalKeyboardKey.keyS: (0x16, 'S'),
    LogicalKeyboardKey.keyT: (0x17, 'T'),
    LogicalKeyboardKey.keyU: (0x18, 'U'),
    LogicalKeyboardKey.keyV: (0x19, 'V'),
    LogicalKeyboardKey.keyW: (0x1A, 'W'),
    LogicalKeyboardKey.keyX: (0x1B, 'X'),
    LogicalKeyboardKey.keyY: (0x1C, 'Y'),
    LogicalKeyboardKey.keyZ: (0x1D, 'Z'),

    // Digits
    LogicalKeyboardKey.digit1: (0x1E, '1'),
    LogicalKeyboardKey.digit2: (0x1F, '2'),
    LogicalKeyboardKey.digit3: (0x20, '3'),
    LogicalKeyboardKey.digit4: (0x21, '4'),
    LogicalKeyboardKey.digit5: (0x22, '5'),
    LogicalKeyboardKey.digit6: (0x23, '6'),
    LogicalKeyboardKey.digit7: (0x24, '7'),
    LogicalKeyboardKey.digit8: (0x25, '8'),
    LogicalKeyboardKey.digit9: (0x26, '9'),
    LogicalKeyboardKey.digit0: (0x27, '0'),

    // Basic Controls & Whitespace
    LogicalKeyboardKey.enter: (0x28, 'Enter'),
    LogicalKeyboardKey.escape: (0x29, 'Esc'),
    LogicalKeyboardKey.backspace: (0x2A, 'Backspace'),
    LogicalKeyboardKey.tab: (0x2B, 'Tab'),
    LogicalKeyboardKey.space: (0x2C, 'Space'),

    // Punctuation & Symbols
    LogicalKeyboardKey.minus: (0x2D, '-'),
    LogicalKeyboardKey.equal: (0x2E, '='),
    LogicalKeyboardKey.bracketLeft: (0x2F, '['),
    LogicalKeyboardKey.bracketRight: (0x30, ']'),
    LogicalKeyboardKey.backslash: (0x31, '\\'),
    LogicalKeyboardKey.semicolon: (0x33, ';'),
    LogicalKeyboardKey.quote: (0x34, "'"),
    LogicalKeyboardKey.backquote: (0x35, '`'),
    LogicalKeyboardKey.comma: (0x36, ','),
    LogicalKeyboardKey.period: (0x37, '.'),
    LogicalKeyboardKey.slash: (0x38, '/'),

    // Lock keys & System/Nav
    LogicalKeyboardKey.capsLock: (0x39, 'Caps Lock'),
    LogicalKeyboardKey.printScreen: (0x46, 'Print Screen'),
    LogicalKeyboardKey.scrollLock: (0x47, 'Scroll Lock'),
    LogicalKeyboardKey.pause: (0x48, 'Pause'),
    LogicalKeyboardKey.insert: (0x49, 'Insert'),
    LogicalKeyboardKey.home: (0x4A, 'Home'),
    LogicalKeyboardKey.pageUp: (0x4B, 'Page Up'),
    LogicalKeyboardKey.delete: (0x4C, 'Delete'),
    LogicalKeyboardKey.end: (0x4D, 'End'),
    LogicalKeyboardKey.pageDown: (0x4E, 'Page Down'),
    LogicalKeyboardKey.arrowRight: (0x4F, 'Right'),
    LogicalKeyboardKey.arrowLeft: (0x50, 'Left'),
    LogicalKeyboardKey.arrowDown: (0x51, 'Down'),
    LogicalKeyboardKey.arrowUp: (0x52, 'Up'),
    LogicalKeyboardKey.numLock: (0x53, 'Num Lock'),
    LogicalKeyboardKey.contextMenu: (0x65, 'Menu'),

    // Numpad
    LogicalKeyboardKey.numpadDivide: (0x54, 'Numpad /'),
    LogicalKeyboardKey.numpadMultiply: (0x55, 'Numpad *'),
    LogicalKeyboardKey.numpadSubtract: (0x56, 'Numpad -'),
    LogicalKeyboardKey.numpadAdd: (0x57, 'Numpad +'),
    LogicalKeyboardKey.numpadEnter: (0x58, 'Numpad Enter'),
    LogicalKeyboardKey.numpad1: (0x59, 'Numpad 1'),
    LogicalKeyboardKey.numpad2: (0x5A, 'Numpad 2'),
    LogicalKeyboardKey.numpad3: (0x5B, 'Numpad 3'),
    LogicalKeyboardKey.numpad4: (0x5C, 'Numpad 4'),
    LogicalKeyboardKey.numpad5: (0x5D, 'Numpad 5'),
    LogicalKeyboardKey.numpad6: (0x5E, 'Numpad 6'),
    LogicalKeyboardKey.numpad7: (0x5F, 'Numpad 7'),
    LogicalKeyboardKey.numpad8: (0x60, 'Numpad 8'),
    LogicalKeyboardKey.numpad9: (0x61, 'Numpad 9'),
    LogicalKeyboardKey.numpad0: (0x62, 'Numpad 0'),
    LogicalKeyboardKey.numpadDecimal: (0x63, 'Numpad Del'),
    LogicalKeyboardKey.numpadEqual: (0x67, 'Numpad ='),

    // Function keys (F1 - F24)
    LogicalKeyboardKey.f1: (0x3A, 'F1'),
    LogicalKeyboardKey.f2: (0x3B, 'F2'),
    LogicalKeyboardKey.f3: (0x3C, 'F3'),
    LogicalKeyboardKey.f4: (0x3D, 'F4'),
    LogicalKeyboardKey.f5: (0x3E, 'F5'),
    LogicalKeyboardKey.f6: (0x3F, 'F6'),
    LogicalKeyboardKey.f7: (0x40, 'F7'),
    LogicalKeyboardKey.f8: (0x41, 'F8'),
    LogicalKeyboardKey.f9: (0x42, 'F9'),
    LogicalKeyboardKey.f10: (0x43, 'F10'),
    LogicalKeyboardKey.f11: (0x44, 'F11'),
    LogicalKeyboardKey.f12: (0x45, 'F12'),
    LogicalKeyboardKey.f13: (0x68, 'F13'),
    LogicalKeyboardKey.f14: (0x69, 'F14'),
    LogicalKeyboardKey.f15: (0x6A, 'F15'),
    LogicalKeyboardKey.f16: (0x6B, 'F16'),
    LogicalKeyboardKey.f17: (0x6C, 'F17'),
    LogicalKeyboardKey.f18: (0x6D, 'F18'),
    LogicalKeyboardKey.f19: (0x6E, 'F19'),
    LogicalKeyboardKey.f20: (0x6F, 'F20'),
    LogicalKeyboardKey.f21: (0x70, 'F21'),
    LogicalKeyboardKey.f22: (0x71, 'F22'),
    LogicalKeyboardKey.f23: (0x72, 'F23'),
    LogicalKeyboardKey.f24: (0x73, 'F24'),

    // Modifiers
    LogicalKeyboardKey.controlLeft: (0xE0, 'Ctrl'),
    LogicalKeyboardKey.controlRight: (0xE4, 'Right Ctrl'),
    LogicalKeyboardKey.shiftLeft: (0xE1, 'Shift'),
    LogicalKeyboardKey.shiftRight: (0xE5, 'Right Shift'),
    LogicalKeyboardKey.altLeft: (0xE2, 'Alt'),
    LogicalKeyboardKey.altRight: (0xE6, 'Right Alt'),
    LogicalKeyboardKey.metaLeft: (0xE3, 'Win'),
    LogicalKeyboardKey.metaRight: (0xE7, 'Right Win'),
    LogicalKeyboardKey.control: (0xE0, 'Ctrl'),
    LogicalKeyboardKey.shift: (0xE1, 'Shift'),
    LogicalKeyboardKey.alt: (0xE2, 'Alt'),
    LogicalKeyboardKey.meta: (0xE3, 'Win'),
  };

  static final Map<int, String> _keyCodesToLabel = {
    for (final entry in _logicalKeyToCodeAndLabel.values) entry.$1: entry.$2,
  };

  static final Map<String, int> _keyCodes = {
    for (final entry in _logicalKeyToCodeAndLabel.values) entry.$2: entry.$1,
    for (var i = 0; i < 26; i++) String.fromCharCode(97 + i): 0x04 + i,
  };

  static final Map<LogicalKeyboardKey, String> _logicalKeyLabels = {
    for (final entry in _logicalKeyToCodeAndLabel.entries)
      entry.key: entry.value.$2,
  };
}

ButtonStyle _macroOutlinedButtonStyle(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return OutlinedButton.styleFrom(
    backgroundColor: isDark ? const Color(0xFF26282E) : Colors.white,
    foregroundColor: theme.colorScheme.onSurface,
    minimumSize: const Size(80, 42),
    side: BorderSide(
      color: (isDark ? const Color(0xFF3F424B) : const Color(0xFFD0D5DD)),
      width: 1.0,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    elevation: 1.5,
    shadowColor: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
  );
}



class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap?.call(),
      showCheckmark: false,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: isDark ? const Color(0xFF26282E) : Colors.white,
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected
            ? Colors.white
            : (isDark ? const Color(0xFFE0E3EB) : const Color(0xFF344054)),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : (isDark ? const Color(0xFF3F424B) : const Color(0xFFD0D5DD)),
          width: 1.0,
        ),
      ),
    );
  }
}

class _EmptyMacroState extends StatelessWidget {
  const _EmptyMacroState({super.key, required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.extension_rounded,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              t.macro.noMacrosConfigured,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.macro.noMacrosConfiguredDesc,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              style: _macroOutlinedButtonStyle(context),
              label: Text(t.macro.createMacro),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroSelectionEmptyState extends StatelessWidget {
  const _MacroSelectionEmptyState({required this.onNewMacro});

  final VoidCallback onNewMacro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.extension_rounded,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              t.macro.selectShortcutEdit,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.macro.selectShortcutEditDesc,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onNewMacro,
              icon: const Icon(Icons.add_rounded, size: 18),
              style: _macroOutlinedButtonStyle(context),
              label: Text(t.macro.newMacro),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.action, required this.onDelete});
  final MacroAction action;
  final VoidCallback onDelete;

  bool get _isWheelOrTilt =>
      action.keyCode == MacroWireActions.wheelUp ||
      action.keyCode == MacroWireActions.wheelDown ||
      action.keyCode == MacroWireActions.tiltLeft ||
      action.keyCode == MacroWireActions.tiltRight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isKeyDown = !action.isBreak;
    final badgeColor = _isWheelOrTilt
        ? (isDark ? const Color(0xFF00838F) : const Color(0xFF00ACC1))
        : (isKeyDown
              ? (isDark ? const Color(0xFF1E88E5) : const Color(0xFF1976D2))
              : (isDark ? const Color(0xFFE65100) : const Color(0xFFF57C00)));

    final eventTypeLabel = _isWheelOrTilt
        ? t.macro.wheel
        : (action.isBreak ? t.macro.keyUp : t.macro.keyDown);

    final eventIcon = _isWheelOrTilt
        ? Icons.mouse_rounded
        : (action.isBreak
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded);

    final displayLabel = action.label != null
        ? (CatalogLocalization.localizeLabelString(action.label!, t) ??
            action.label!)
        : '0x${action.keyCode.toRadixString(16)}';

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerLowest,
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Key / Action Label on Left (width 130 ensures Wheel Down fits on one line)
          SizedBox(
            width: 130,
            child: Text(
              displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // Key Down / Key Up / Wheel Badge Centered in Middle
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(minWidth: 70, maxWidth: 110),
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  children: [
                    Icon(eventIcon, size: 13, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      eventTypeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Delay ms Container on Right (fixed 85x24 container)
          Container(
            width: 85,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.06,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${action.delay * _macroDelayUnitMs} ms',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded, size: 16),
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: t.macro.removeAction,
          ),
        ],
      ),
    );
  }
}

class MacroToast extends StatelessWidget {
  const MacroToast({super.key, required this.message, required this.isSuccess});

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isSuccess
                  ? const Color(0xFF70C050)
                  : const Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.close,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
