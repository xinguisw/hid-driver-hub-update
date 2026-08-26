import 'dart:convert';

/// One row in an action-catalog section (static product UI list).
///
/// L2 blueprint only — ids are catalog keys, not HID frames.
class ActionCatalogItem {
  final String id;
  final String label;

  /// Optional UI role (e.g. special tab: `modifier` / `any_key`).
  final String? role;

  const ActionCatalogItem({
    required this.id,
    required this.label,
    this.role,
  });

  factory ActionCatalogItem.fromJson(Map<String, dynamic> json) {
    return ActionCatalogItem(
      id: json['id'] as String,
      label: json['label'] as String,
      role: json['role'] as String?,
    );
  }
}

/// Grouped rows under one section title (e.g. "Mouse Action").
class ActionCatalogSection {
  final String title;
  final List<ActionCatalogItem> items;

  const ActionCatalogSection({required this.title, required this.items});

  factory ActionCatalogSection.fromJson(Map<String, dynamic> json) {
    return ActionCatalogSection(
      title: json['title'] as String,
      items: (json['items'] as List)
          .map((e) => ActionCatalogItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

/// One action-catalog tab payload (e.g. Mouse tab).
class ActionCatalogTab {
  final String id;
  final String tab;
  final List<ActionCatalogSection> sections;

  /// Optional layout hint: omit/`list` = section list; `combination` = Special UI.
  final String? layout;

  const ActionCatalogTab({
    required this.id,
    required this.tab,
    required this.sections,
    this.layout,
  });

  factory ActionCatalogTab.fromJson(Map<String, dynamic> json) {
    return ActionCatalogTab(
      id: json['id'] as String,
      tab: json['tab'] as String,
      layout: json['layout'] as String?,
      sections: (json['sections'] as List)
          .map((e) => ActionCatalogSection.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

/// Provides inlined static action-catalog definitions.
///
/// Pure Dart constants — no asynchronous file I/O or JSON parsing overhead.
class ActionCatalogStore {
  ActionCatalogStore._();

  static const ActionCatalogTab _mouseTab = ActionCatalogTab(
    id: 'action.mouse',
    tab: 'mouse',
    sections: [
      ActionCatalogSection(
        title: 'Mouse',
        items: [
          ActionCatalogItem(id: 'mouse.disable', label: 'Disable'),
          ActionCatalogItem(id: 'mouse.left', label: 'Left Button'),
          ActionCatalogItem(id: 'mouse.right', label: 'Right Button'),
          ActionCatalogItem(id: 'mouse.middle', label: 'Middle Button'),
          ActionCatalogItem(id: 'mouse.forward', label: 'Forward Button'),
          ActionCatalogItem(id: 'mouse.backward', label: 'Backward Button'),
        ],
      ),
      ActionCatalogSection(
        title: 'Mouse Action',
        items: [
          ActionCatalogItem(
            id: 'mouse.report_rate_cycle',
            label: 'Report Rate Cycle',
          ),
          ActionCatalogItem(id: 'mouse.dpi_cycle', label: 'DPI Cycle'),
          ActionCatalogItem(id: 'mouse.dpi_up', label: 'DPI +'),
          ActionCatalogItem(id: 'mouse.dpi_down', label: 'DPI -'),
        ],
      ),
      ActionCatalogSection(
        title: 'Mouse Wheel Action',
        items: [
          ActionCatalogItem(id: 'mouse.wheel_up', label: 'Wheel Up'),
          ActionCatalogItem(id: 'mouse.wheel_down', label: 'Wheel Down'),
          ActionCatalogItem(id: 'mouse.tilt_left', label: 'Tilt Left'),
          ActionCatalogItem(id: 'mouse.tilt_right', label: 'Tilt Right'),
        ],
      ),
      ActionCatalogSection(
        title: 'Multimedia',
        items: [
          ActionCatalogItem(id: 'mouse.volume_up', label: 'Volume Up'),
          ActionCatalogItem(id: 'mouse.volume_down', label: 'Volume Down'),
          ActionCatalogItem(id: 'mouse.volume_mute', label: 'Volume Mute'),
          ActionCatalogItem(id: 'mouse.next_track', label: 'Next Track'),
          ActionCatalogItem(id: 'mouse.prev_track', label: 'Previous Track'),
          ActionCatalogItem(id: 'mouse.stop', label: 'Stop'),
          ActionCatalogItem(id: 'mouse.play_pause', label: 'Play / Pause'),
        ],
      ),
      ActionCatalogSection(
        title: 'Consumer',
        items: [
          ActionCatalogItem(id: 'mouse.web_search', label: 'Web Search'),
          ActionCatalogItem(id: 'mouse.web_home', label: 'Web Home'),
          ActionCatalogItem(id: 'mouse.web_back', label: 'Web Back'),
          ActionCatalogItem(id: 'mouse.web_forward', label: 'Web Forward'),
          ActionCatalogItem(id: 'mouse.web_stop', label: 'Web Stop'),
          ActionCatalogItem(id: 'mouse.web_refresh', label: 'Web Refresh'),
          ActionCatalogItem(
            id: 'mouse.web_favourite',
            label: 'Web Favourite',
          ),
          ActionCatalogItem(id: 'mouse.media_player', label: 'Media Player'),
          ActionCatalogItem(id: 'mouse.email', label: 'Email'),
          ActionCatalogItem(id: 'mouse.calculator', label: 'Calculator'),
          ActionCatalogItem(id: 'mouse.my_computer', label: 'My Computer'),
        ],
      ),
    ],
  );

  static const ActionCatalogTab _keyboardTab = ActionCatalogTab(
    id: 'action.keyboard',
    tab: 'keyboard',
    sections: [
      ActionCatalogSection(
        title: 'Letter & Symbol & Number keys',
        items: [
          ActionCatalogItem(id: 'key.letter.a', label: 'A'),
          ActionCatalogItem(id: 'key.letter.b', label: 'B'),
          ActionCatalogItem(id: 'key.letter.c', label: 'C'),
          ActionCatalogItem(id: 'key.letter.d', label: 'D'),
          ActionCatalogItem(id: 'key.letter.e', label: 'E'),
          ActionCatalogItem(id: 'key.letter.f', label: 'F'),
          ActionCatalogItem(id: 'key.letter.g', label: 'G'),
          ActionCatalogItem(id: 'key.letter.h', label: 'H'),
          ActionCatalogItem(id: 'key.letter.i', label: 'I'),
          ActionCatalogItem(id: 'key.letter.j', label: 'J'),
          ActionCatalogItem(id: 'key.letter.k', label: 'K'),
          ActionCatalogItem(id: 'key.letter.l', label: 'L'),
          ActionCatalogItem(id: 'key.letter.m', label: 'M'),
          ActionCatalogItem(id: 'key.letter.n', label: 'N'),
          ActionCatalogItem(id: 'key.letter.o', label: 'O'),
          ActionCatalogItem(id: 'key.letter.p', label: 'P'),
          ActionCatalogItem(id: 'key.letter.q', label: 'Q'),
          ActionCatalogItem(id: 'key.letter.r', label: 'R'),
          ActionCatalogItem(id: 'key.letter.s', label: 'S'),
          ActionCatalogItem(id: 'key.letter.t', label: 'T'),
          ActionCatalogItem(id: 'key.letter.u', label: 'U'),
          ActionCatalogItem(id: 'key.letter.v', label: 'V'),
          ActionCatalogItem(id: 'key.letter.w', label: 'W'),
          ActionCatalogItem(id: 'key.letter.x', label: 'X'),
          ActionCatalogItem(id: 'key.letter.y', label: 'Y'),
          ActionCatalogItem(id: 'key.letter.z', label: 'Z'),
          ActionCatalogItem(id: 'key.digit.1', label: '1'),
          ActionCatalogItem(id: 'key.digit.2', label: '2'),
          ActionCatalogItem(id: 'key.digit.3', label: '3'),
          ActionCatalogItem(id: 'key.digit.4', label: '4'),
          ActionCatalogItem(id: 'key.digit.5', label: '5'),
          ActionCatalogItem(id: 'key.digit.6', label: '6'),
          ActionCatalogItem(id: 'key.digit.7', label: '7'),
          ActionCatalogItem(id: 'key.digit.8', label: '8'),
          ActionCatalogItem(id: 'key.digit.9', label: '9'),
          ActionCatalogItem(id: 'key.digit.0', label: '0'),
          ActionCatalogItem(id: 'key.sym.minus', label: '-'),
          ActionCatalogItem(id: 'key.sym.equals', label: '='),
          ActionCatalogItem(id: 'key.sym.lbracket', label: '['),
          ActionCatalogItem(id: 'key.sym.rbracket', label: ']'),
          ActionCatalogItem(id: 'key.sym.backslash', label: '\\'),
          ActionCatalogItem(id: 'key.sym.semicolon', label: ';'),
          ActionCatalogItem(id: 'key.sym.quote', label: "'"),
          ActionCatalogItem(id: 'key.sym.grave', label: '`'),
          ActionCatalogItem(id: 'key.sym.comma', label: ','),
          ActionCatalogItem(id: 'key.sym.period', label: '.'),
          ActionCatalogItem(id: 'key.sym.slash', label: '/'),
          ActionCatalogItem(id: 'key.sym.space', label: 'Space'),
          ActionCatalogItem(id: 'key.sym.enter', label: 'Enter'),
          ActionCatalogItem(id: 'key.sym.esc', label: 'Esc'),
          ActionCatalogItem(id: 'key.sym.backspace', label: 'Backspace'),
          ActionCatalogItem(id: 'key.sym.tab', label: 'Tab'),
          ActionCatalogItem(id: 'key.nav.insert', label: 'Insert'),
          ActionCatalogItem(id: 'key.nav.home', label: 'Home'),
          ActionCatalogItem(id: 'key.nav.pageup', label: 'Page Up'),
          ActionCatalogItem(id: 'key.nav.delete', label: 'Delete'),
          ActionCatalogItem(id: 'key.nav.end', label: 'End'),
          ActionCatalogItem(id: 'key.nav.pagedown', label: 'Page Down'),
          ActionCatalogItem(id: 'key.nav.up', label: 'Up'),
          ActionCatalogItem(id: 'key.nav.down', label: 'Down'),
          ActionCatalogItem(id: 'key.nav.left', label: 'Left'),
          ActionCatalogItem(id: 'key.nav.right', label: 'Right'),
          ActionCatalogItem(id: 'key.nav.print', label: 'Print Screen'),
          ActionCatalogItem(id: 'key.nav.scroll', label: 'Scroll Lock'),
          ActionCatalogItem(id: 'key.nav.pause', label: 'Pause'),
        ],
      ),
      ActionCatalogSection(
        title: 'Numeric Keypad Keys',
        items: [
          ActionCatalogItem(id: 'key.num.0', label: '0'),
          ActionCatalogItem(id: 'key.num.1', label: '1'),
          ActionCatalogItem(id: 'key.num.2', label: '2'),
          ActionCatalogItem(id: 'key.num.3', label: '3'),
          ActionCatalogItem(id: 'key.num.4', label: '4'),
          ActionCatalogItem(id: 'key.num.5', label: '5'),
          ActionCatalogItem(id: 'key.num.6', label: '6'),
          ActionCatalogItem(id: 'key.num.7', label: '7'),
          ActionCatalogItem(id: 'key.num.8', label: '8'),
          ActionCatalogItem(id: 'key.num.9', label: '9'),
          ActionCatalogItem(id: 'key.num.div', label: '/'),
          ActionCatalogItem(id: 'key.num.mul', label: '*'),
          ActionCatalogItem(id: 'key.num.sub', label: '-'),
          ActionCatalogItem(id: 'key.num.add', label: '+'),
          ActionCatalogItem(id: 'key.num.enter', label: 'Numpad Enter'),
          ActionCatalogItem(id: 'key.num.del', label: 'Numpad Del'),
          ActionCatalogItem(id: 'key.num.lock', label: 'Num Lock'),
        ],
      ),
      ActionCatalogSection(
        title: 'Modifier Key',
        items: [
          ActionCatalogItem(id: 'key.mod.capslk', label: 'Caps Lock'),
          ActionCatalogItem(id: 'key.mod.shift', label: 'Left Shift'),
          ActionCatalogItem(id: 'key.mod.ctrl', label: 'Left Ctrl'),
          ActionCatalogItem(id: 'key.mod.alt', label: 'Left Alt'),
          ActionCatalogItem(id: 'key.mod.win', label: 'Left Win'),
          ActionCatalogItem(id: 'key.mod.rshift', label: 'Right Shift'),
          ActionCatalogItem(id: 'key.mod.rctrl', label: 'Right Ctrl'),
          ActionCatalogItem(id: 'key.mod.ralt', label: 'Right Alt'),
          ActionCatalogItem(id: 'key.mod.rwin', label: 'Right Win'),
        ],
      ),
    ],
  );

  static const ActionCatalogTab _specialTab = ActionCatalogTab(
    id: 'action.special',
    tab: 'special',
    layout: 'combination',
    sections: [
      ActionCatalogSection(
        title: 'Combination Keys',
        items: [
          ActionCatalogItem(
            id: 'special.mod.alt',
            label: 'Left Alt',
            role: 'modifier',
          ),
          ActionCatalogItem(
            id: 'special.mod.ctrl',
            label: 'Left Ctrl',
            role: 'modifier',
          ),
          ActionCatalogItem(
            id: 'special.mod.win',
            label: 'Left Win',
            role: 'modifier',
          ),
          ActionCatalogItem(
            id: 'special.mod.shift',
            label: 'Left Shift',
            role: 'modifier',
          ),
          ActionCatalogItem(
            id: 'special.any_key',
            label: 'Any key',
            role: 'any_key',
          ),
        ],
      ),
    ],
  );

  static const Map<String, ActionCatalogTab> _staticTabs = {
    'mouse': _mouseTab,
    'keyboard': _keyboardTab,
    'special': _specialTab,
  };

  static String assetPathForTab(String tab) =>
      'assets/catalog/action/${tab.toLowerCase()}.json';

  /// Synchronously or asynchronously returns inlined action catalog tab.
  static Future<ActionCatalogTab> load(String tab) async {
    final key = tab.toLowerCase();
    final catalog = _staticTabs[key];
    if (catalog != null) return catalog;
    throw ArgumentError('Unknown action catalog tab: $tab');
  }

  /// Cached tab or null if unknown.
  static ActionCatalogTab? forTab(String tab) => _staticTabs[tab.toLowerCase()];

  /// No-op helper for backwards compatibility in tests.
  static void clearCache() {}
}

