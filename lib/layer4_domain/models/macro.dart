import 'package:driver_hub/layer2_capabilities/capabilities.dart';

/// Domain representation of one Telink B80 macro.
///
/// The domain keeps semantic values and does not know the HID frame layout.
/// L5 converts these values to the 67-byte MacroPacket described by the
/// protocol reference.
enum MacroMode {
  loop(0x00, 'Loop'),
  // SDRD FR-MCR-003: continuous until keyboard keystroke or mouse click.
  stopOnAnyKey(0x01, 'Stop on any key or mouse click'),
  playOnHold(0x02, 'Play on hold');

  const MacroMode(this.wireValue, this.label);

  final int wireValue;
  final String label;

  static MacroMode fromWire(int value) {
    for (final mode in values) {
      if (mode.wireValue == value) return mode;
    }
    throw FormatException(
      'Unsupported macro mode: 0x${value.toRadixString(16)}',
    );
  }
}

/// One two-byte MacroAction, before its attribute byte is packed by L5.
class MacroAction {
  const MacroAction({
    required this.keyCode,
    required this.isBreak,
    required this.delay,
    this.label,
  });
  const MacroAction.wheelUp({
    required bool isBreak,
    required int delay,
    String? label,
  }) : this(
         keyCode: MacroWireActions.wheelUp,
         isBreak: isBreak,
         delay: delay,
         label: label,
       );

  const MacroAction.wheelDown({
    required bool isBreak,
    required int delay,
    String? label,
  }) : this(
         keyCode: MacroWireActions.wheelDown,
         isBreak: isBreak,
         delay: delay,
         label: label,
       );

  const MacroAction.tiltLeft({
    required bool isBreak,
    required int delay,
    String? label,
  }) : this(
         keyCode: MacroWireActions.tiltLeft,
         isBreak: isBreak,
         delay: delay,
         label: label,
       );

  const MacroAction.tiltRight({
    required bool isBreak,
    required int delay,
    String? label,
  }) : this(
         keyCode: MacroWireActions.tiltRight,
         isBreak: isBreak,
         delay: delay,
         label: label,
       );

  /// Keyboard, mouse, or timing-special code from the protocol reference.
  final int keyCode;

  /// True for a break event; false for a make event.
  final bool isBreak;

  /// Attribute bits 6..0. The protocol defines this as delay or a special
  /// code timebase multiplier; the unit is intentionally preserved as the
  /// protocol value instead of being guessed as milliseconds.
  final int delay;

  /// Optional UI label. It is not sent to the device.
  final String? label;

  MacroAction copyWith({
    int? keyCode,
    bool? isBreak,
    int? delay,
    String? label,
  }) {
    return MacroAction(
      keyCode: keyCode ?? this.keyCode,
      isBreak: isBreak ?? this.isBreak,
      delay: delay ?? this.delay,
      label: label ?? this.label,
    );
  }

  Map<String, Object?> toJson() => {
    'keyCode': keyCode,
    'isBreak': isBreak,
    'delay': delay,
    if (label != null) 'label': label,
  };

  factory MacroAction.fromJson(Map<String, Object?> json) {
    return MacroAction(
      keyCode: _asInt(json['keyCode'], 'keyCode'),
      isBreak: json['isBreak'] == true,
      delay: _asInt(json['delay'], 'delay'),
      label: json['label'] as String?,
    );
  }
}

/// A saved macro assigned to one hardware slot (M1..M16).
class MacroDefinition {
  const MacroDefinition({
    required this.slot,
    required this.name,
    required this.mode,
    required this.loopTimes,
    required this.actions,
  });

  static const maxSlots = 16;
  static const maxActions = 30;
  static const maxNameLength = 30;

  final int slot;
  final String name;
  final MacroMode mode;
  final int loopTimes;
  final List<MacroAction> actions;

  MacroDefinition copyWith({
    int? slot,
    String? name,
    MacroMode? mode,
    int? loopTimes,
    List<MacroAction>? actions,
  }) {
    return MacroDefinition(
      slot: slot ?? this.slot,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      loopTimes: loopTimes ?? this.loopTimes,
      actions: List.unmodifiable(actions ?? this.actions),
    );
  }

  Map<String, Object?> toJson() => {
    'slot': slot,
    'name': name,
    'mode': mode.wireValue,
    'loopTimes': loopTimes,
    'actions': actions.map((a) => a.toJson()).toList(growable: false),
  };

  factory MacroDefinition.fromJson(Map<String, Object?> json) {
    final rawActions = json['actions'];
    if (rawActions is! List) {
      throw const FormatException('Macro actions must be a list');
    }
    return MacroDefinition(
      slot: _asInt(json['slot'], 'slot'),
      name: json['name'] as String? ?? '',
      mode: MacroMode.fromWire(_asInt(json['mode'], 'mode')),
      loopTimes: _asInt(json['loopTimes'], 'loopTimes'),
      actions: List.unmodifiable(
        rawActions.map((raw) {
          if (raw is! Map) throw const FormatException('Invalid macro action');
          return MacroAction.fromJson(Map<String, Object?>.from(raw));
        }),
      ),
    );
  }
}

/// A mutable-in-practice immutable draft used by the editor and L4 service.
class MacroDraft {
  const MacroDraft({
    required this.slot,
    required this.name,
    required this.mode,
    required this.loopTimes,
    required this.actions,
  });

  final int slot;
  final String name;
  final MacroMode mode;
  final int loopTimes;
  final List<MacroAction> actions;

  MacroDraft copyWith({
    int? slot,
    String? name,
    MacroMode? mode,
    int? loopTimes,
    List<MacroAction>? actions,
  }) {
    return MacroDraft(
      slot: slot ?? this.slot,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      loopTimes: loopTimes ?? this.loopTimes,
      actions: List.unmodifiable(actions ?? this.actions),
    );
  }

  MacroDefinition toDefinition() => MacroDefinition(
    slot: slot,
    name: name,
    mode: mode,
    loopTimes: loopTimes,
    actions: actions,
  );
}

List<String> validateMacro(MacroDefinition macro) {
  final errors = <String>[];
  if (macro.slot < 1 || macro.slot > MacroDefinition.maxSlots) {
    errors.add('Macro slot must be between 1 and 16');
  }
  if (macro.loopTimes < 1 || macro.loopTimes > 0xFF) {
    errors.add('Loop count must be between 1 and 255');
  }
  if (macro.name.length > MacroDefinition.maxNameLength) {
    errors.add(
      'Macro name must not exceed ${MacroDefinition.maxNameLength} characters',
    );
  }
  if (macro.actions.isEmpty ||
      macro.actions.length > MacroDefinition.maxActions) {
    errors.add('Macro must contain between 1 and 30 actions');
  }
  for (var i = 0; i < macro.actions.length; i++) {
    final action = macro.actions[i];
    if (action.delay < 0 || action.delay > 0x7F) {
      errors.add('Action ${i + 1} delay must be between 0 and 127');
    }
    final isKeyboard =
        (action.keyCode >= 0x04 && action.keyCode <= 0xA4) ||
        (action.keyCode >= 0xE0 && action.keyCode <= 0xE7);
    // Macro mouse-button key codes are 0xC1 (Left) to 0xC5 (Backward).
    final isMouseButton = action.keyCode >= 0xC1 && action.keyCode <= 0xC5;
    final isMouseWheel =
        action.keyCode == MacroWireActions.wheelUp ||
        action.keyCode == MacroWireActions.wheelDown;
    final isMouse = isMouseButton || isMouseWheel;
    final isTiming = action.keyCode >= 0x01 && action.keyCode <= 0x03;
    if (!isKeyboard && !isMouse && !isTiming) {
      errors.add('Action ${i + 1} has an unsupported key code');
    }
  }
  return errors;
}

int _asInt(Object? value, String field) {
  if (value is int) return value;
  throw FormatException('Macro $field must be an integer');
}
