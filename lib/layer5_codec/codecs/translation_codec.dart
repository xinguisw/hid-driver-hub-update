/// Pure wire → display maps for settings (and later SET reverse maps).
///
/// L5 protocol parse stays raw; L1 packs through this. One home for every
/// field translation (report rate, DPI mask, buttons, …).
class TranslationCodec {
  const TranslationCodec();

  /// Report-rate wire (interval ms) → Hz. Null if unknown.
  ///
  /// `1→1000`, `2→500`, `4→250`, `8→125`.
  int? reportRateWireToHz(int wire) {
    switch (wire) {
      case 1:
        return 1000;
      case 2:
        return 500;
      case 4:
        return 250;
      case 8:
        return 125;
      default:
        return null;
    }
  }

  /// Active-stage **bitmask** → count of active stages (`0x1F` → 5).
  int dpiActiveMaskToCount(int mask) {
    var n = 0;
    var m = mask & 0xFF;
    while (m != 0) {
      n += m & 1;
      m >>= 1;
    }
    return n;
  }

  /// True if 0-based stage [index] is enabled in [mask] (`0x1F` → 0..4).
  bool dpiStageIndexActive(int mask, int index) {
    if (index < 0 || index > 7) return false;
    return (mask & (1 << index)) != 0;
  }

  /// Current DPI stage: wire 0-based → display 1-based.
  int dpiCurrentLevelWireToDisplay(int wire) => wire + 1;

  /// Combine wire bytes into one unsigned integer ([endian] big/little).
  ///
  /// Example (`identity`): bytes `03 20` → `0x0320` → display 800.
  int dpiAxisBytesToWire(List<int> bytes, {String endian = 'big'}) {
    if (bytes.isEmpty) return 0;
    if (endian == 'little') {
      var v = 0;
      for (var i = 0; i < bytes.length; i++) {
        v |= (bytes[i] & 0xFF) << (8 * i);
      }
      return v;
    }
    // big-endian: first byte is most significant (0x03,0x20 → 0x0320)
    var v = 0;
    for (final b in bytes) {
      v = (v << 8) | (b & 0xFF);
    }
    return v;
  }

  /// Wire unit → display DPI for the active sensor transform.
  ///
  /// Transforms are selected per sensor profile (`sensors.json`):
  /// - `identity` — wire value is DPI (`0x0320` → 800)
  /// - `divide` — display = wire × factor
  /// - `multiply` — display = wire ÷ factor
  /// - `paw3311` — [cpiMap] when present; else `(wire + 1) × factor`
  int dpiWireUnitToDisplay(
    int wire, {
    required String transform,
    required int factor,
    Map<int, int> cpiMap = const {},
  }) {
    switch (transform) {
      case 'identity':
        return wire;
      case 'divide':
        return wire * factor;
      case 'multiply':
        if (factor == 0) {
          throw ArgumentError.value(factor, 'factor', 'multiply factor must be non-zero');
        }
        return wire ~/ factor;
      case 'paw3311':
        final mapped = cpiMap[wire & 0xFF];
        if (mapped != null) return mapped;
        return (wire + 1) * factor;
      default:
        throw ArgumentError.value(transform, 'transform', 'unknown DPI transform');
    }
  }

  /// Decode one C4 stage using the sensor encoding for this device.
  ///
  /// [bytesPerAxis], [independentXY], [transform], [factor], and [cpiMap]
  /// come from the device’s sensor table — not hard-coded chip names.
  ({int value, int? y}) decodeDpiStageWire({
    required int b0,
    required int b1,
    required int bytesPerAxis,
    required String endian,
    required bool independentXY,
    required String transform,
    required int factor,
    Map<int, int> cpiMap = const {},
  }) {
    if (!independentXY) {
      final wire = bytesPerAxis == 1
          ? (b0 & 0xFF)
          : dpiAxisBytesToWire([b0 & 0xFF, b1 & 0xFF], endian: endian);
      final dpi = dpiWireUnitToDisplay(
        wire,
        transform: transform,
        factor: factor,
        cpiMap: cpiMap,
      );
      return (value: dpi, y: null);
    }
    final x = dpiWireUnitToDisplay(
      b0 & 0xFF,
      transform: transform,
      factor: factor,
      cpiMap: cpiMap,
    );
    final y = dpiWireUnitToDisplay(
      b1 & 0xFF,
      transform: transform,
      factor: factor,
      cpiMap: cpiMap,
    );
    return (value: x, y: y);
  }

  /// Physical button slot name (1-based id).
  String buttonIdToLabel(int buttonId) {
    switch (buttonId) {
      case 1:
        return 'Left';
      case 2:
        return 'Right';
      case 3:
        return 'Middle';
      case 4:
        return 'Forward';
      case 5:
        return 'Backward';
      case 6:
        return 'DPI cycle';
      default:
        return 'Button $buttonId';
    }
  }

  /// Button mapping action + params → display label.
  ///
  /// Shortcut / consumer actions resolve their params via [keyComboToLabel].
  String buttonActionToLabel({
    required int action,
    int param1 = 0,
    int param2 = 0,
    int param3 = 0,
  }) {
    switch (action) {
      case 0x00:
        return 'Disable / No action';
      case 0x01:
        return 'Button off';
      case 0x02:
        return 'Left click';
      case 0x03:
        return 'Right click';
      case 0x04:
        return 'Middle click';
      case 0x05:
        return 'Forward';
      case 0x06:
        return 'Backward';
      case 0x07:
        return 'Scroll up';
      case 0x08:
        return 'Scroll down';
      case 0x09:
        return 'Swing left';
      case 0x0A:
        return 'Swing right';
      case 0x0B:
        return 'DPI increase';
      // 0x0C unused in protocol enum
      case 0x0D:
        return 'DPI decrease';
      case 0x0E:
        return 'DPI cycle';
      case 0x0F:
        return 'Report rate';
      case 0x10:
        return 'Profile cycle';
      case 0x11:
        return 'Sniper';
      case 0x12:
      case 0x13:
        return keyComboToLabel(param1, param2, param3);
      case 0x14:
        return 'Macro play (#$param1)';
      default:
        return 'Unknown action 0x${action.toRadixString(16)} '
            '(p=$param1,$param2,$param3)';
    }
  }

  /// Shortcut / consumer keyvalue slots → one combined label.
  ///
  /// @param p1 first keyvalue slot; `0` means empty.
  /// @param p2 second keyvalue slot; `0` means empty.
  /// @param p3 third keyvalue slot; `0` means empty.
  /// @returns modifiers then key joined by ` + `, e.g. `Ctrl + Alt + C`.
  String keyComboToLabel(int p1, int p2, int p3) {
    final mods = <String>[];
    final keys = <String>[];
    for (final v in [p1, p2, p3]) {
      if (v == 0) continue;
      // why: a key may occupy any slot, so classify on the byte value and
      // never on its position.
      if (v >= _modifierFirst && v <= _modifierLast) {
        mods.add(keyValueToLabel(v));
      } else {
        keys.add(keyValueToLabel(v));
      }
    }
    if (mods.isEmpty && keys.isEmpty) return 'Not assigned';
    return [...mods, ...keys].join(' + ');
  }

  /// Keyvalue byte → key name.
  ///
  /// @returns `Key 0xNN` for a byte with no assigned name.
  String keyValueToLabel(int value) =>
      _keyValues[value] ?? 'Key 0x${value.toRadixString(16).padLeft(2, '0')}';

  static const int _modifierFirst = 0xE0;
  static const int _modifierLast = 0xE7;

  static const Map<int, String> _keyValues = {
    0x01: 'Win lock',

    // Letters
    0x04: 'A', 0x05: 'B', 0x06: 'C', 0x07: 'D', 0x08: 'E', 0x09: 'F',
    0x0A: 'G', 0x0B: 'H', 0x0C: 'I', 0x0D: 'J', 0x0E: 'K', 0x0F: 'L',
    0x10: 'M', 0x11: 'N', 0x12: 'O', 0x13: 'P', 0x14: 'Q', 0x15: 'R',
    0x16: 'S', 0x17: 'T', 0x18: 'U', 0x19: 'V', 0x1A: 'W', 0x1B: 'X',
    0x1C: 'Y', 0x1D: 'Z',

    // Digits
    0x1E: '1', 0x1F: '2', 0x20: '3', 0x21: '4', 0x22: '5',
    0x23: '6', 0x24: '7', 0x25: '8', 0x26: '9', 0x27: '0',

    // Basic control
    0x28: 'Enter', 0x29: 'Esc', 0x2A: 'Backspace', 0x2B: 'Tab',
    0x2C: 'Space', 0x39: 'Caps Lock',

    // Punctuation
    0x2D: '-', 0x2E: '=', 0x2F: '[', 0x30: ']', 0x31: '\\',
    0x32: 'K42', 0x33: ';', 0x34: "'", 0x35: '`', 0x36: ',',
    0x37: '.', 0x38: '/',

    // Function keys
    0x3A: 'F1', 0x3B: 'F2', 0x3C: 'F3', 0x3D: 'F4', 0x3E: 'F5',
    0x3F: 'F6', 0x40: 'F7', 0x41: 'F8', 0x42: 'F9', 0x43: 'F10',
    0x44: 'F11', 0x45: 'F12',
    0x68: 'F13', 0x69: 'F14', 0x6A: 'F15', 0x6B: 'F16', 0x6C: 'F17',
    0x6D: 'F18', 0x6E: 'F19', 0x6F: 'F20', 0x70: 'F21', 0x71: 'F22',
    0x72: 'F23', 0x73: 'F24',

    // Navigation and editing
    0x46: 'Print Screen', 0x47: 'Scroll Lock', 0x48: 'Pause',
    0x49: 'Insert', 0x4A: 'Home', 0x4B: 'Page Up', 0x4C: 'Delete',
    0x4D: 'End', 0x4E: 'Page Down',
    0x4F: 'Right', 0x50: 'Left', 0x51: 'Down', 0x52: 'Up',

    // Numpad
    0x53: 'Num Lock', 0x54: 'Numpad /', 0x55: 'Numpad *',
    0x56: 'Numpad -', 0x57: 'Numpad +', 0x58: 'Numpad Enter',
    0x59: 'Numpad 1', 0x5A: 'Numpad 2', 0x5B: 'Numpad 3',
    0x5C: 'Numpad 4', 0x5D: 'Numpad 5', 0x5E: 'Numpad 6',
    0x5F: 'Numpad 7', 0x60: 'Numpad 8', 0x61: 'Numpad 9',
    0x62: 'Numpad 0', 0x63: 'Numpad Del', 0x67: 'Numpad =',

    // Miscellaneous keyboard
    0x64: 'K45', 0x65: 'Menu', 0x66: 'Power',
    0x85: 'K107', 0x87: 'K56', 0x88: 'K133', 0x89: 'K14',
    0x8A: 'K132', 0x8B: 'K131', 0x90: 'K150', 0x91: 'K151',
    0xD6: 'Alt + NBSP', 0xD7: 'Shift + NBSP',

    // System power
    0xA0: 'Sleep', 0xA1: 'System power', 0xA2: 'Wake up',

    // Consumer
    0xA3: 'Web search', 0xA4: 'Web home', 0xA5: 'Web back',
    0xA6: 'Web forward', 0xA7: 'Web stop', 0xA8: 'Web refresh',
    0xA9: 'Web favourites', 0xAA: 'Media player', 0xAB: 'Email',
    0xAC: 'Calculator', 0xAD: 'My computer', 0xAE: 'Next track',
    0xAF: 'Previous track', 0xB0: 'Stop', 0xB1: 'Play / pause',
    0xB2: 'Mute', 0xB3: 'Volume up', 0xB4: 'Volume down',
    0xB5: 'Vendor key', 0xB6: 'Zoom in', 0xB7: 'Zoom out',
    0xB8: 'Pan left', 0xB9: 'Pan right', 0xBA: 'Brightness up',
    0xBB: 'Brightness down', 0xBC: 'Reject call', 0xBD: 'Media power',
    0xBE: 'Terminal lock',

    // Mouse
    0xC0: 'DPI', 0xC1: 'Left click', 0xC2: 'Right click',
    0xC3: 'Middle click', 0xC4: 'Mouse button 4',
    0xC5: 'Mouse button 5', 0xC6: 'Wheel up', 0xC7: 'Wheel down',

    // Tool
    0xC8: 'Device power', 0xC9: 'Bind', 0xCA: 'Keyboard', 0xCB: 'Lock',
    0xCC: 'Brightness up', 0xCD: 'Brightness down', 0xCE: 'Language',
    0xCF: 'Copy', 0xD0: 'Paste', 0xD1: 'Cut', 0xD2: 'Phone',
    0xD3: 'Print Screen', 0xD4: 'Backlight', 0xD5: 'Task manager',

    // Modifiers
    0xE0: 'Ctrl', 0xE1: 'Shift', 0xE2: 'Alt', 0xE3: 'Win',
    0xE4: 'Right Ctrl', 0xE5: 'Right Shift', 0xE6: 'Right Alt',
    0xE7: 'Right Win',

    // Gamepad
    0xDD: 'Gamepad Start', 0xDE: 'Gamepad Back',
    0xDF: 'Gamepad Select', 0xF0: 'Gamepad A', 0xF1: 'Gamepad B',
    0xF2: 'Gamepad X', 0xF3: 'Gamepad Y', 0xF4: 'D-pad Left',
    0xF5: 'D-pad Down', 0xF6: 'D-pad Up', 0xF7: 'D-pad Right',
    0xF8: 'L1', 0xF9: 'R1', 0xFA: 'L2', 0xFB: 'R2', 0xFC: 'L3',
    0xFD: 'R3', 0xFE: 'Gamepad Home',

    0xFF: 'Fn',
  };
}
