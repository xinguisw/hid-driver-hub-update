import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Macro Settings page — macro list (left) + editor (right).
///
/// Recording is live: Start Recording captures real key down/up events with
/// inter-event delays into the Record list. No persistence or L4 wiring yet.
class HubMacroPanel extends StatefulWidget {
  const HubMacroPanel({super.key});

  @override
  State<HubMacroPanel> createState() => _HubMacroPanelState();
}

class _RecordedEvent {
  const _RecordedEvent(this.keyLabel, this.isDown, this.delayMs);

  final String keyLabel;
  final bool isDown;

  /// Milliseconds since the previous recorded event (0 for the first).
  final int delayMs;
}

class _HubMacroPanelState extends State<HubMacroPanel> {
  final FocusNode _recordFocus = FocusNode();
  final List<_RecordedEvent> _events = [];
  bool _recording = false;
  bool _showCreation = false;
  DateTime? _lastEventAt;

  @override
  void dispose() {
    _recordFocus.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _recording = true;
      _events.clear();
      _lastEventAt = null;
    });
    // why: key events only reach a focused node — grab it on start
    _recordFocus.requestFocus();
  }

  void _stopRecording() {
    setState(() => _recording = false);
    _recordFocus.unfocus();
  }

  void _openCreation() {
    setState(() => _showCreation = true);
  }

  KeyEventResult _onRecordKeyEvent(FocusNode node, KeyEvent event) {
    if (!_recording) return KeyEventResult.ignored;
    final isDown = switch (event) {
      KeyDownEvent() => true,
      KeyUpEvent() => false,
      _ => null, // KeyRepeatEvent: key held — not a new event
    };
    if (isDown == null) return KeyEventResult.handled;

    final label = _keyLabel(event);
    if (label == null) return KeyEventResult.handled;

    final now = DateTime.now();
    final delay =
        _lastEventAt == null ? 0 : now.difference(_lastEventAt!).inMilliseconds;
    setState(() {
      _events.add(_RecordedEvent(label, isDown, delay));
      _lastEventAt = now;
    });
    // why: handled keeps recorded keys out of focused fields/buttons
    return KeyEventResult.handled;
  }

  /// Display label for [event]: printable character first, else named key.
  static String? _keyLabel(KeyEvent event) {
    final raw = event.character;
    if (raw != null &&
        raw.isNotEmpty &&
        raw.characters.first.codeUnitAt(0) >= 0x20) {
      return raw.characters.first;
    }
    return _logicalKeyLabels[event.logicalKey];
  }

  static final Map<LogicalKeyboardKey, String> _logicalKeyLabels = {
    LogicalKeyboardKey.escape: 'Esc',
    LogicalKeyboardKey.enter: 'Enter',
    LogicalKeyboardKey.tab: 'Tab',
    LogicalKeyboardKey.backspace: 'Backspace',
    LogicalKeyboardKey.space: 'Space',
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
    LogicalKeyboardKey.shiftLeft: 'Shift',
    LogicalKeyboardKey.shiftRight: 'Shift',
    LogicalKeyboardKey.controlLeft: 'Ctrl',
    LogicalKeyboardKey.controlRight: 'Ctrl',
    LogicalKeyboardKey.altLeft: 'Alt',
    LogicalKeyboardKey.altRight: 'Alt',
    for (var i = 1; i <= 12; i++)
      LogicalKeyboardKey(0x00000000030 + i): 'F$i',
  };

  @override
  Widget build(BuildContext context) {
    if (!_showCreation) {
      return _EmptyMacroState(onCreate: _openCreation);
    }

    return _buildMacroEditor(context);
  }

  Widget _buildMacroEditor(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: macro list — 20% of panel width.
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
                  onPressed: null, // skeleton — not wired yet
                  child: const Text('New Macro'),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              // Placeholder entries.
              for (final name in const ['M1'])
                ListTile(
                  dense: true,
                  title: Text(name),
                  onTap: null, // skeleton
                ),
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        // Right: editor — 80% of panel width.
        // Focus hugs the editor so scrolling shortcuts don't eat key events.
        Expanded(
          flex: 4,
          child: Focus(
            focusNode: _recordFocus,
            onKeyEvent: _onRecordKeyEvent,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'M1',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Macro type + loop count bar.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('macro type + loop count input',
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 12),
                  // Record controls.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _recording ? null : _startRecording,
                        child: const Text('Start Recording'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _recording ? _stopRecording : null,
                        child: const Text('Stop Recording'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Recorded event list — header + rows in one container.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
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
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          for (final e in _events)
                            _MacroRow(
                              keyName: e.keyLabel,
                              event: e.isDown ? 'KeyDown' : 'KeyUp',
                              delay: '${e.delayMs} ms',
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: null, // skeleton
                    child: const Text('+ Insert Mouse Button'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: null, // skeleton
                    child: const Text('+ Insert Keyboard Key'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: null, // skeleton
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: null, // skeleton
                        child: const Text('Save'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: null, // skeleton
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyMacroState extends StatelessWidget {
  const _EmptyMacroState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No macros configured'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onCreate,
            child: const Text('Create Macro'),
          ),
        ],
      ),
    );
  }
}

/// One recorded macro row: key name + down/up event + delay + delete (inert).
class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.keyName,
    required this.event,
    required this.delay,
  });

  final String keyName;
  final String event;
  final String delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(keyName),
          // Event centers against the whole row; trailing side stays pinned.
          Expanded(child: Center(child: Text(event))),
          // Fixed-width right-aligned slot: values line up regardless of digits.
          SizedBox(
            width: 64,
            child: Text(delay, textAlign: TextAlign.right),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.delete_outline, size: 16),
        ],
      ),
    );
  }
}
