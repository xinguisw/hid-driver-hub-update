import 'package:driver_hub/layer2_capabilities/capabilities.dart';

/// Wire keyvalue byte → display name, and combo assembly.
///
/// Owned by L5 as a standalone table so [TranslationCodec] (and later SET
/// encode) can consume it without embedding the map.
class KeyvalueTable {
  const KeyvalueTable();

  static const int modifierFirst = 0xE0;
  static const int modifierLast = 0xE7;

  /// Keyvalue byte → key name.
  ///
  /// @returns `Key 0xNN` for a byte with no assigned name.
  String keyValueToLabel(int value) =>
      labels[value] ?? 'Key 0x${value.toRadixString(16).padLeft(2, '0')}';

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
      if (v >= modifierFirst && v <= modifierLast) {
        mods.add(keyValueToLabel(v));
      } else {
        keys.add(keyValueToLabel(v));
      }
    }
    if (mods.isEmpty && keys.isEmpty) return 'Not assigned';
    return [...mods, ...keys].join(' + ');
  }

  /// Full keyvalue → label map. Edit here to add / change / remove keys.
  static const Map<int, String> labels = {
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
    0x4D: 'End', 0x4E: 'Page Down', 0x4F: 'Right Arrow',
    0x50: 'Left Arrow', 0x51: 'Down Arrow', 0x52: 'Up Arrow',
    0x53: 'Num Lock',

    // Numpad
    0x54: 'Numpad /', 0x55: 'Numpad *',
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

    // Consumer / Media
    0xA0: 'Web back', 0xA1: 'Web forward', 0xA2: 'Web refresh',
    0xA3: 'Web search', 0xA4: 'Web home', 0xA5: 'Web back',
    0xA6: 'Web forward', 0xA7: 'Web stop', 0xA8: 'Web refresh',
    0xA9: 'Web favourites', 0xAA: 'Media player', 0xAB: 'Email',
    0xAC: 'Calculator', 0xAD: 'My computer', 0xAE: 'Next track',
    0xAF: 'Previous track', 0xB0: 'Stop', 0xB1: 'Play / pause',
    0xB2: 'Volume Mute', 0xB3: 'Volume Up', 0xB4: 'Volume Down',
    0xB5: 'Vendor key', 0xB6: 'Zoom in', 0xB7: 'Zoom out',
    0xB8: 'Tilt Right', 0xB9: 'Tilt Left', 0xBA: 'Brightness up',
    0xBB: 'Brightness down', 0xBC: 'Reject call', 0xBD: 'Media power',
    0xBE: 'Terminal lock',

    // Mouse
    0xC0: 'DPI', 0xC1: 'Left Button', 0xC2: 'Right Button',
    0xC3: 'Middle Button', 0xC4: 'Forward Button',
    0xC5: 'Backward Button',
    MacroWireActions.wheelUp: 'Wheel Up',
    MacroWireActions.wheelDown: 'Wheel Down',

    // Tool
    0xC8: 'Device power', 0xC9: 'Bind', 0xCA: 'Keyboard', 0xCB: 'Lock',
    0xCC: 'Brightness up', 0xCD: 'Brightness down', 0xCE: 'Language',
    0xCF: 'Copy', 0xD0: 'Paste', 0xD1: 'Cut', 0xD2: 'Phone',
    0xD3: 'Print Screen', 0xD4: 'Backlight', 0xD5: 'Task manager',

    // Modifiers
    0xE0: 'Left Ctrl', 0xE1: 'Left Shift', 0xE2: 'Left Alt', 0xE3: 'Left Win',
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
