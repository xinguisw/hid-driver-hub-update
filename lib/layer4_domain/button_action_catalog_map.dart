import 'package:driver_hub/layer4_domain/models/button_mapping_slot.dart';

/// L4 domain: catalog action ID → wire [ButtonMappingSlot].
///
/// Translates L2 catalog IDs (e.g. `"mouse.left"`) into the wire bytes
/// that L5 encodes. L3 passes only the catalog ID; L4 owns the mapping.
///
/// **Maintenance note:** This table must stay in sync with:
/// - L2 catalog JSONs: `assets/catalog/action/{mouse,keyboard,special}.json`
/// - L5 [TranslationCodec.buttonActionToLabel] (reverse map)
/// - L5 [KeyvalueTable.labels] (keyboard key bytes)
class ButtonActionCatalogMap {
  ButtonActionCatalogMap._();

  /// Catalog ID → wire slot. Returns `null` if the ID is unknown.
  static ButtonMappingSlot? catalogIdToSlot(String catalogId) {
    final entry = _table[catalogId];
    if (entry == null) return null;
    return ButtonMappingSlot(
      action: entry[0],
      param1: entry.length > 1 ? entry[1] : 0,
      param2: entry.length > 2 ? entry[2] : 0,
      param3: entry.length > 3 ? entry[3] : 0,
    );
  }

  /// Wire table: [action, param1?, param2?, param3?].
  ///
  /// Mouse actions: action byte only (0x00–0x14 range).
  /// Keyboard shortcuts: action 0x12, key byte in param1.
  /// Special modifiers: action byte 0xE0–0xE7.
  static const Map<String, List<int>> _table = {
    // --- Mouse tab ---
    'mouse.disable': [0x00],
    'mouse.left': [0x02],
    'mouse.right': [0x03],
    'mouse.middle': [0x04],
    'mouse.forward': [0x05],
    'mouse.backward': [0x06],
    'mouse.report_rate_cycle': [0x0F],
    'mouse.dpi_cycle': [0x0E],
    'mouse.dpi_up': [0x0B],
    'mouse.dpi_down': [0x0D],
    'mouse.wheel_up': [0x07],
    'mouse.wheel_down': [0x08],
    'mouse.tilt_left': [0x09],
    'mouse.tilt_right': [0x0A],

    // --- Keyboard tab (action 0x12 = shortcut, key byte in param1) ---
    // Letters
    'key.letter.a': [0x12, 0x04],
    'key.letter.b': [0x12, 0x05],
    'key.letter.c': [0x12, 0x06],
    'key.letter.d': [0x12, 0x07],
    'key.letter.e': [0x12, 0x08],
    'key.letter.f': [0x12, 0x09],
    'key.letter.g': [0x12, 0x0A],
    'key.letter.h': [0x12, 0x0B],
    'key.letter.i': [0x12, 0x0C],
    'key.letter.j': [0x12, 0x0D],
    'key.letter.k': [0x12, 0x0E],
    'key.letter.l': [0x12, 0x0F],
    'key.letter.m': [0x12, 0x10],
    'key.letter.n': [0x12, 0x11],
    'key.letter.o': [0x12, 0x12],
    'key.letter.p': [0x12, 0x13],
    'key.letter.q': [0x12, 0x14],
    'key.letter.r': [0x12, 0x15],
    'key.letter.s': [0x12, 0x16],
    'key.letter.t': [0x12, 0x17],
    'key.letter.u': [0x12, 0x18],
    'key.letter.v': [0x12, 0x19],
    'key.letter.w': [0x12, 0x1A],
    'key.letter.x': [0x12, 0x1B],
    'key.letter.y': [0x12, 0x1C],
    'key.letter.z': [0x12, 0x1D],

    // Digits
    'key.digit.1': [0x12, 0x1E],
    'key.digit.2': [0x12, 0x1F],
    'key.digit.3': [0x12, 0x20],
    'key.digit.4': [0x12, 0x21],
    'key.digit.5': [0x12, 0x22],
    'key.digit.6': [0x12, 0x23],
    'key.digit.7': [0x12, 0x24],
    'key.digit.8': [0x12, 0x25],
    'key.digit.9': [0x12, 0x26],
    'key.digit.0': [0x12, 0x27],

    // Symbols
    'key.sym.minus': [0x12, 0x2D],
    'key.sym.equals': [0x12, 0x2E],
    'key.sym.lbracket': [0x12, 0x2F],
    'key.sym.rbracket': [0x12, 0x30],
    'key.sym.backslash': [0x12, 0x31],
    'key.sym.semicolon': [0x12, 0x33],
    'key.sym.quote': [0x12, 0x34],
    'key.sym.grave': [0x12, 0x35],
    'key.sym.comma': [0x12, 0x36],
    'key.sym.period': [0x12, 0x37],
    'key.sym.slash': [0x12, 0x38],
    'key.sym.space': [0x12, 0x2C],
    'key.sym.enter': [0x12, 0x28],
    'key.sym.esc': [0x12, 0x29],
    'key.sym.backspace': [0x12, 0x2A],
    'key.sym.tab': [0x12, 0x2B],

    // Function keys
    'key.f1': [0x12, 0x3A],
    'key.f2': [0x12, 0x3B],
    'key.f3': [0x12, 0x3C],
    'key.f4': [0x12, 0x3D],
    'key.f5': [0x12, 0x3E],
    'key.f6': [0x12, 0x3F],
    'key.f7': [0x12, 0x40],
    'key.f8': [0x12, 0x41],
    'key.f9': [0x12, 0x42],
    'key.f10': [0x12, 0x43],
    'key.f11': [0x12, 0x44],
    'key.f12': [0x12, 0x45],

    // Navigation
    'key.nav.insert': [0x12, 0x49],
    'key.nav.home': [0x12, 0x4A],
    'key.nav.pageup': [0x12, 0x4B],
    'key.nav.delete': [0x12, 0x4C],
    'key.nav.end': [0x12, 0x4D],
    'key.nav.pagedown': [0x12, 0x4E],
    'key.nav.up': [0x12, 0x52],
    'key.nav.down': [0x12, 0x51],
    'key.nav.left': [0x12, 0x50],
    'key.nav.right': [0x12, 0x4F],
    'key.nav.print': [0x12, 0x46],
    'key.nav.scroll': [0x12, 0x47],
    'key.nav.pause': [0x12, 0x48],

    // Numpad
    'key.num.0': [0x12, 0x62],
    'key.num.1': [0x12, 0x59],
    'key.num.2': [0x12, 0x5A],
    'key.num.3': [0x12, 0x5B],
    'key.num.4': [0x12, 0x5C],
    'key.num.5': [0x12, 0x5D],
    'key.num.6': [0x12, 0x5E],
    'key.num.7': [0x12, 0x5F],
    'key.num.8': [0x12, 0x60],
    'key.num.9': [0x12, 0x61],
    'key.num.div': [0x12, 0x54],
    'key.num.mul': [0x12, 0x55],
    'key.num.sub': [0x12, 0x56],
    'key.num.add': [0x12, 0x57],
    'key.num.enter': [0x12, 0x58],
    'key.num.del': [0x12, 0x63],
    'key.num.lock': [0x12, 0x53],
    'key.num.eq': [0x12, 0x67],

    // Modifiers (keyboard tab)
    'key.mod.capslk': [0x12, 0x39],
    'key.mod.shift': [0x12, 0xE1],
    'key.mod.ctrl': [0x12, 0xE0],
    'key.mod.alt': [0x12, 0xE2],
    'key.mod.win': [0x12, 0xE3],
    'key.mod.rshift': [0x12, 0xE5],
    'key.mod.rctrl': [0x12, 0xE4],
    'key.mod.ralt': [0x12, 0xE6],
    'key.mod.rwin': [0x12, 0xE7],

    // --- Special tab (modifier bytes, action = the byte itself) ---
    'special.mod.alt': [0xE2],
    'special.mod.ctrl': [0xE0],
    'special.mod.win': [0xE3],
    'special.mod.shift': [0xE1],
  };
}
