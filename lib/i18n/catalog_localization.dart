import 'package:driver_hub/i18n/strings.g.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer5_codec/codecs/keyvalue_table.dart';

/// Helper utility for localizing catalog section titles, action items,
/// and dynamic button/action labels.
class CatalogLocalization {
  CatalogLocalization._();

  /// Translates catalog section title into current locale.
  static String localizeSectionTitle(String title, Translations t) {
    switch (title.trim()) {
      case 'Mouse':
        return t.mapping.mouse;
      case 'Mouse Action':
        return t.mapping.mouseAction;
      case 'Mouse Wheel Action':
        return t.mapping.mouseWheelAction;
      case 'Multimedia':
        return t.mapping.multimedia;
      case 'Consumer':
        return t.mapping.consumer;
      case 'Combination Keys':
        return t.mapping.combinationKeys;
      case 'Letter & Symbol & Number keys':
        return t.mapping.letterSymbolNumberKeys;
      case 'Numeric Keypad Keys':
        return t.mapping.numericKeypadKeys;
      case 'Modifier Key':
        return t.mapping.modifierKey;
      case 'Macro Setting':
        return t.sidebar.macroSetting;
      default:
        return title;
    }
  }

  /// Translates catalog action item label by its id (falling back to label).
  static String localizeItemLabel(String id, String rawLabel, Translations t) {
    if (t.$meta.locale == AppLocale.en && rawLabel.isNotEmpty) {
      return rawLabel;
    }
    switch (id) {
      case 'mouse.disable':
        return t.actions.disable;
      case 'mouse.left':
        return t.actions.left;
      case 'mouse.right':
        return t.actions.right;
      case 'mouse.middle':
        return t.actions.middle;
      case 'mouse.forward':
        return t.actions.forward;
      case 'mouse.backward':
        return t.actions.backward;
      case 'mouse.report_rate_cycle':
        return t.actions.reportRateCycle;
      case 'mouse.dpi_cycle':
        return t.actions.dpiCycle;
      case 'mouse.dpi_up':
        return t.actions.dpiUp;
      case 'mouse.dpi_down':
        return t.actions.dpiDown;
      case 'mouse.wheel_up':
        return t.actions.wheelUp;
      case 'mouse.wheel_down':
        return t.actions.wheelDown;
      case 'mouse.tilt_left':
        return t.actions.tiltLeft;
      case 'mouse.tilt_right':
        return t.actions.tiltRight;
      case 'mouse.volume_up':
        return t.actions.volumeUp;
      case 'mouse.volume_down':
        return t.actions.volumeDown;
      case 'mouse.volume_mute':
        return t.actions.volumeMute;
      case 'mouse.next_track':
        return t.actions.nextTrack;
      case 'mouse.prev_track':
        return t.actions.prevTrack;
      case 'mouse.stop':
        return t.actions.stop;
      case 'mouse.play_pause':
        return t.actions.playPause;
      case 'mouse.web_search':
        return t.actions.webSearch;
      case 'mouse.web_home':
        return t.actions.webHome;
      case 'mouse.web_back':
        return t.actions.webBack;
      case 'mouse.web_forward':
        return t.actions.webForward;
      case 'mouse.web_stop':
        return t.actions.webStop;
      case 'mouse.web_refresh':
        return t.actions.webRefresh;
      case 'mouse.web_favourite':
        return t.actions.webFavourite;
      case 'mouse.media_player':
        return t.actions.mediaPlayer;
      case 'mouse.email':
        return t.actions.email;
      case 'mouse.calculator':
        return t.actions.calculator;
      case 'mouse.my_computer':
        return t.actions.myComputer;
      case 'special.mod.alt':
        return t.actions.leftAlt;
      case 'special.mod.ctrl':
        return t.actions.leftCtrl;
      case 'special.mod.win':
        return t.actions.leftWin;
      case 'special.mod.shift':
        return t.actions.leftShift;
      case 'special.any_key':
        return t.actions.anyKey;

      // Keyboard action item IDs
      case 'key.sym.space':
        return t.actions.space;
      case 'key.sym.enter':
        return t.actions.enter;
      case 'key.sym.esc':
        return t.actions.esc;
      case 'key.sym.backspace':
        return t.actions.backspace;
      case 'key.sym.tab':
        return t.actions.tab;
      case 'key.nav.insert':
        return t.actions.insert;
      case 'key.nav.home':
        return t.actions.home;
      case 'key.nav.pageup':
        return t.actions.pageUp;
      case 'key.nav.delete':
        return t.actions.delete;
      case 'key.nav.end':
        return t.actions.end;
      case 'key.nav.pagedown':
        return t.actions.pageDown;
      case 'key.nav.up':
        return t.actions.upArrow;
      case 'key.nav.down':
        return t.actions.downArrow;
      case 'key.nav.left':
        return '向左 (Left)';
      case 'key.nav.right':
        return '向右 (Right)';
      case 'key.nav.print':
        return t.actions.printScreen;
      case 'key.nav.scroll':
        return t.actions.scrollLock;
      case 'key.nav.pause':
        return t.actions.pause;
      case 'key.num.enter':
        return t.actions.numpadEnter;
      case 'key.num.del':
        return t.actions.numpadDel;
      case 'key.num.lock':
        return t.actions.numLock;
      case 'key.mod.capslk':
        return t.actions.capsLock;
      case 'key.mod.shift':
        return t.actions.leftShift;
      case 'key.mod.ctrl':
        return t.actions.leftCtrl;
      case 'key.mod.alt':
        return t.actions.leftAlt;
      case 'key.mod.win':
        return t.actions.leftWin;
      case 'key.mod.rshift':
        return t.actions.rightShift;
      case 'key.mod.rctrl':
        return t.actions.rightCtrl;
      case 'key.mod.ralt':
        return t.actions.rightAlt;
      case 'key.mod.rwin':
        return t.actions.rightWin;
      default:
        return localizeLabelString(rawLabel, t) ?? rawLabel;
    }
  }

  /// Translates a button's callout label (e.g. for canvas display).
  static String localizeButtonCallout(ButtonData b, Translations t) {
    // If action is known, translate based on action code
    if (b.action != null) {
      final translated = _actionCodeToLabel(b.action!, b.param1 ?? 0, b.param2 ?? 0, b.param3 ?? 0, t);
      if (translated != null) return translated;
    }

    // Translate based on actionLabel string
    if (b.actionLabel != null && b.actionLabel!.isNotEmpty) {
      final translated = localizeLabelString(b.actionLabel!, t);
      if (translated != null) return translated;
      return b.actionLabel!;
    }

    // Translate based on button slot ID
    if (b.id != 0) {
      return _slotIdToLabel(b.id, t);
    }

    if (b.buttonLabel != null && b.buttonLabel!.isNotEmpty) {
      return localizeLabelString(b.buttonLabel!, t) ?? b.buttonLabel!;
    }

    return 'B${b.id}';
  }

  /// Translates standard label strings (e.g. from TranslationCodec).
  static String? localizeLabelString(String label, Translations t) {
    switch (label.trim()) {
      case 'Left Button':
      case 'Left click':
      case 'Left':
        return t.actions.left;
      case 'Right Button':
      case 'Right click':
      case 'Right':
        return t.actions.right;
      case 'Middle Button':
      case 'Middle click':
      case 'Middle':
        return t.actions.middle;
      case 'Forward Button':
      case 'Forward':
        return t.actions.forward;
      case 'Backward Button':
      case 'Backward':
      case 'Back Button':
      case 'Back':
        return t.actions.backward;
      case 'DPI Cycle':
      case 'DPI cycle':
        return t.actions.dpiCycle;
      case 'Report Rate Cycle':
      case 'Report rate':
        return t.actions.reportRateCycle;
      case 'Wheel Up':
      case 'Scroll up':
        return t.actions.wheelUp;
      case 'Wheel Down':
      case 'Scroll down':
        return t.actions.wheelDown;
      case 'Tilt Left':
      case 'Swing left':
        return t.actions.tiltLeft;
      case 'Tilt Right':
      case 'Swing right':
        return t.actions.tiltRight;
      case 'DPI +':
      case 'DPI increase':
        return t.actions.dpiUp;
      case 'DPI -':
      case 'DPI decrease':
        return t.actions.dpiDown;
      case 'Disable':
      case 'Disable / No action':
      case 'Button off':
        return t.actions.disable;
      case 'Profile Cycle':
      case 'Profile cycle':
        return t.actions.profileCycle;
      case 'Sniper':
        return t.actions.sniper;
      case 'Volume Up':
      case 'Volume up':
        return t.actions.volumeUp;
      case 'Volume Down':
      case 'Volume down':
        return t.actions.volumeDown;
      case 'Volume Mute':
      case 'Volume mute':
        return t.actions.volumeMute;
      case 'Next Track':
      case 'Next track':
        return t.actions.nextTrack;
      case 'Previous Track':
      case 'Previous track':
        return t.actions.prevTrack;
      case 'Stop':
      case 'stop':
        return t.actions.stop;
      case 'Play / Pause':
      case 'Play / pause':
        return t.actions.playPause;
      case 'Web Search':
      case 'Web search':
        return t.actions.webSearch;
      case 'Web Home':
      case 'Web home':
        return t.actions.webHome;
      case 'Web Back':
      case 'Web back':
        return t.actions.webBack;
      case 'Web Forward':
      case 'Web forward':
        return t.actions.webForward;
      case 'Web Stop':
      case 'Web stop':
        return t.actions.webStop;
      case 'Web Refresh':
      case 'Web refresh':
        return t.actions.webRefresh;
      case 'Web Favourite':
      case 'Web favourite':
      case 'Web favourites':
        return t.actions.webFavourite;
      case 'Media Player':
      case 'Media player':
        return t.actions.mediaPlayer;
      case 'Email':
      case 'email':
        return t.actions.email;
      case 'Calculator':
      case 'calculator':
        return t.actions.calculator;
      case 'My Computer':
      case 'My computer':
        return t.actions.myComputer;
      case 'Left Alt':
        return t.actions.leftAlt;
      case 'Left Ctrl':
        return t.actions.leftCtrl;
      case 'Left Win':
        return t.actions.leftWin;
      case 'Left Shift':
        return t.actions.leftShift;
      case 'Right Alt':
        return t.actions.rightAlt;
      case 'Right Ctrl':
        return t.actions.rightCtrl;
      case 'Right Win':
        return t.actions.rightWin;
      case 'Right Shift':
        return t.actions.rightShift;
      case 'Any key':
        return t.actions.anyKey;
      case 'Caps Lock':
        return t.actions.capsLock;
      case 'Space':
        return t.actions.space;
      case 'Enter':
        return t.actions.enter;
      case 'Esc':
        return t.actions.esc;
      case 'Backspace':
        return t.actions.backspace;
      case 'Tab':
        return t.actions.tab;
      case 'Insert':
        return t.actions.insert;
      case 'Home':
        return t.actions.home;
      case 'Page Up':
        return t.actions.pageUp;
      case 'Page Down':
        return t.actions.pageDown;
      case 'Delete':
        return t.actions.delete;
      case 'End':
        return t.actions.end;
      case 'Up':
      case 'Up Arrow':
        return t.actions.upArrow;
      case 'Down':
      case 'Down Arrow':
        return t.actions.downArrow;
      case 'Left Arrow':
        return t.actions.leftArrow;
      case 'Right Arrow':
        return t.actions.rightArrow;
      case 'Print Screen':
        return t.actions.printScreen;
      case 'Scroll Lock':
        return t.actions.scrollLock;
      case 'Pause':
        return t.actions.pause;
      case 'Num Lock':
        return t.actions.numLock;
      case 'Numpad Enter':
        return t.actions.numpadEnter;
      case 'Numpad Del':
        return t.actions.numpadDel;
      case 'Numpad +':
        return t.actions.numpadAdd;
      case 'Numpad -':
        return t.actions.numpadSub;
      case 'Numpad *':
        return t.actions.numpadMul;
      case 'Numpad /':
        return t.actions.numpadDiv;
      default:
        if (label.contains(' + ')) {
          final parts = label.split(' + ');
          return parts
              .map((part) => localizeLabelString(part, t) ?? part)
              .join(' + ');
        }
        if (label.startsWith('Button ')) {
          final id = int.tryParse(label.replaceFirst('Button ', ''));
          if (id != null) return t.actions.button(id: id);
        }
        return null;
    }
  }

  static String _slotIdToLabel(int id, Translations t) {
    switch (id) {
      case 1:
        return t.actions.left;
      case 2:
        return t.actions.right;
      case 3:
        return t.actions.middle;
      case 4:
        return t.actions.forward;
      case 5:
        return t.actions.backward;
      case 6:
        return t.actions.dpiCycle;
      default:
        return t.actions.button(id: id);
    }
  }

  static String? _actionCodeToLabel(
    int action,
    int p1,
    int p2,
    int p3,
    Translations t,
  ) {
    switch (action) {
      case 0x00:
      case 0x01:
        return t.actions.disable;
      case 0x02:
        return t.actions.left;
      case 0x03:
        return t.actions.right;
      case 0x04:
        return t.actions.middle;
      case 0x05:
        return t.actions.forward;
      case 0x06:
        return t.actions.backward;
      case 0x07:
        return t.actions.wheelUp;
      case 0x08:
        return t.actions.wheelDown;
      case 0x09:
        return t.actions.tiltLeft;
      case 0x0A:
        return t.actions.tiltRight;
      case 0x0B:
        return t.actions.dpiUp;
      case 0x0D:
        return t.actions.dpiDown;
      case 0x0E:
        return t.actions.dpiCycle;
      case 0x0F:
        return t.actions.reportRateCycle;
      case 0x10:
        return t.actions.profileCycle;
      case 0x11:
        return t.actions.sniper;
      case 0x12:
      case 0x13:
        return _keyComboToLocalizedLabel(p1, p2, p3, t);
      case 0x14:
        return 'M$p1';
      default:
        return null;
    }
  }

  static String _keyComboToLocalizedLabel(
    int p1,
    int p2,
    int p3,
    Translations t,
  ) {
    final mods = <String>[];
    final keys = <String>[];
    for (final v in [p1, p2, p3]) {
      if (v == 0) continue;
      if (v >= 0xE0 && v <= 0xE7) {
        final raw = _modifierByteToLabel(v);
        mods.add(localizeLabelString(raw, t) ?? raw);
      } else {
        final raw = _keyByteToLabel(v);
        keys.add(localizeLabelString(raw, t) ?? raw);
      }
    }
    if (mods.isEmpty && keys.isEmpty) return t.actions.disable;
    return [...mods, ...keys].join(' + ');
  }

  static String _modifierByteToLabel(int v) {
    return KeyvalueTable.labels[v] ?? 'Mod 0x${v.toRadixString(16)}';
  }

  static String _keyByteToLabel(int v) {
    return KeyvalueTable.labels[v] ?? 'Key 0x${v.toRadixString(16)}';
  }
}
