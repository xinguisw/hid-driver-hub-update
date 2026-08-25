import 'package:driver_hub/i18n/strings.g.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';

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
      default:
        return rawLabel;
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
        return t.actions.volumeUp;
      case 'Volume Down':
        return t.actions.volumeDown;
      case 'Volume Mute':
        return t.actions.volumeMute;
      case 'Next Track':
        return t.actions.nextTrack;
      case 'Previous Track':
        return t.actions.prevTrack;
      case 'Stop':
        return t.actions.stop;
      case 'Play / Pause':
        return t.actions.playPause;
      case 'Web Search':
        return t.actions.webSearch;
      case 'Web Home':
        return t.actions.webHome;
      case 'Web Back':
        return t.actions.webBack;
      case 'Web Forward':
        return t.actions.webForward;
      case 'Web Stop':
        return t.actions.webStop;
      case 'Web Refresh':
        return t.actions.webRefresh;
      case 'Web Favourite':
        return t.actions.webFavourite;
      case 'Media Player':
        return t.actions.mediaPlayer;
      case 'Email':
        return t.actions.email;
      case 'Calculator':
        return t.actions.calculator;
      case 'My Computer':
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
    switch (v) {
      case 0xE0:
        return 'Left Ctrl';
      case 0xE1:
        return 'Left Shift';
      case 0xE2:
        return 'Left Alt';
      case 0xE3:
        return 'Left Win';
      case 0xE4:
        return 'Right Ctrl';
      case 0xE5:
        return 'Right Shift';
      case 0xE6:
        return 'Right Alt';
      case 0xE7:
        return 'Right Win';
      default:
        return 'Mod 0x${v.toRadixString(16)}';
    }
  }

  static String _keyByteToLabel(int v) {
    if (v >= 0x04 && v <= 0x1D) {
      return String.fromCharCode(65 + (v - 0x04)); // A..Z
    }
    if (v >= 0x1E && v <= 0x26) {
      return String.fromCharCode(49 + (v - 0x1E)); // 1..9
    }
    if (v == 0x27) return '0';
    switch (v) {
      case 0x28:
        return 'Enter';
      case 0x29:
        return 'Esc';
      case 0x2A:
        return 'Backspace';
      case 0x2B:
        return 'Tab';
      case 0x2C:
        return 'Space';
      case 0x39:
        return 'Caps Lock';
      default:
        return 'Key 0x${v.toRadixString(16)}';
    }
  }
}
