import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer5_codec/codecs/keyvalue_table.dart';

/// L5 wire → meaning maps for settings (and later SET reverse maps).
///
/// **Display standard:** fixed sheet tables use `*ToLabel` → complete
/// strings with unit or name (`1000 Hz`, `2ms`, `1mm`, `On`). Callers
/// must not invent units. Keyvalue names live in [KeyvalueTable].
///
/// **Domain helpers:** `*ToHz` / mask / DPI decode stay numeric for L4
/// options, counts, and staging — not half-finished display labels.
class TranslationCodec {
  const TranslationCodec({this.keyvalues = const KeyvalueTable()});

  /// Standalone keyvalue library (add / change / delete keys there).
  final KeyvalueTable keyvalues;

  // --- Domain helpers (typed product units for L4; not bare wire) ---

  /// Report-rate wire → Hz number for domain options / state.
  ///
  /// Display path: [reportRateWireToLabel]. `1→1000` … `8→125`.
  int? reportRateWireToHz(int wire) {
    switch (wire & 0xFF) {
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

  /// Hz → report-rate wire value. Reverse of [reportRateWireToHz].
  ///
  /// Returns `null` for an unknown Hz so the caller can reject rather than
  /// silently encode a wrong byte.
  int? reportRateHzToWire(int hz) {
    switch (hz) {
      case 1000:
        return 1;
      case 500:
        return 2;
      case 250:
        return 4;
      case 125:
        return 8;
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

  /// Current DPI stage: wire 0-based → 1-based index for domain state.
  int dpiCurrentLevelWireToDisplay(int wire) => wire + 1;

  /// Display level (1-based) → wire 0-based. Reverse of [dpiCurrentLevelWireToDisplay].
  ///
  /// Returns `null` for out-of-range levels so the caller can reject rather than
  /// silently encode a wrong byte.
  int? dpiCurrentLevelDisplayToWire(int level) {
    if (level < 1 || level > 8) return null;
    return level - 1;
  }

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
  /// - `paw3311` — [cpiTables] by register mode; the mode is inferred from
  ///   the value's range (≤10000 → mode 0x50, >10000 → mode 0xD0), falling
  ///   back to the legacy flat [cpiMap], then `(wire + 1) × factor`.
  int dpiWireUnitToDisplay(
    int wire, {
    required String transform,
    required int factor,
    Map<int, int> cpiMap = const {},
    Map<int, Map<int, int>> cpiTables = const {},
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
        // Infer PAW3311 register mode from the CPI range the value maps into:
        // mode 0x50 covers ≤10000, mode 0xD0 covers >10000. Try both.
        for (final mode in [0x50, 0xD0]) {
          final table = cpiTables[mode];
          if (table == null) continue;
          final mapped = table[wire & 0xFF];
          if (mapped != null) return mapped;
        }
        final legacy = cpiMap[wire & 0xFF];
        if (legacy != null) return legacy;
        return (wire + 1) * factor;
      default:
        throw ArgumentError.value(transform, 'transform', 'unknown DPI transform');
    }
  }

  /// Display DPI → wire unit for the active sensor transform (encode).
  ///
  /// Inverse of [dpiWireUnitToDisplay]:
  /// - `identity` — DPI is the wire value (`800` → 0x0320)
  /// - `divide` — wire = DPI ÷ factor
  /// - `multiply` — wire = DPI × factor
  /// - `paw3311` — look up DPI in [cpiTables]; the mode is chosen by the DPI
  ///   value's range (≤10000 → 0x50, >10000 → 0xD0). Falls back to the
  ///   legacy [cpiMap] reverse lookup, then `(DPI ÷ factor) - 1`.
  ///
  /// Returns null if the DPI is not representable in this encoding.
  int? dpiDisplayToWireUnit(
    int dpi, {
    required String transform,
    required int factor,
    Map<int, int> cpiMap = const {},
    Map<int, Map<int, int>> cpiTables = const {},
  }) {
    switch (transform) {
      case 'identity':
        return dpi;
      case 'divide':
        return dpi ~/ factor;
      case 'multiply':
        return dpi * factor;
      case 'paw3311':
        final mode = dpi > 10000 ? 0xD0 : 0x50;
        final table = cpiTables[mode];
        if (table != null) {
          for (final e in table.entries) {
            if (e.value == dpi) return e.key;
          }
        }
        for (final e in cpiMap.entries) {
          if (e.value == dpi) return e.key;
        }
        final fallback = (dpi ~/ factor) - 1;
        return fallback >= 0 ? fallback : null;
      default:
        throw ArgumentError.value(transform, 'transform', 'unknown DPI transform');
    }
  }

  /// Decode one C4 stage using the sensor encoding for this device.
  ///
  /// [bytesPerAxis], [independentXY], [transform], [factor], [cpiMap], and
  /// [cpiTables] come from the device’s sensor table — not hard-coded chips.
  ({int value, int? y}) decodeDpiStageWire({
    required int b0,
    required int b1,
    required int bytesPerAxis,
    required String endian,
    required bool independentXY,
    required String transform,
    required int factor,
    Map<int, int> cpiMap = const {},
    Map<int, Map<int, int>> cpiTables = const {},
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
        cpiTables: cpiTables,
      );
      return (value: dpi, y: null);
    }
    final x = dpiWireUnitToDisplay(
      b0 & 0xFF,
      transform: transform,
      factor: factor,
      cpiMap: cpiMap,
      cpiTables: cpiTables,
    );
    final y = dpiWireUnitToDisplay(
      b1 & 0xFF,
      transform: transform,
      factor: factor,
      cpiMap: cpiMap,
      cpiTables: cpiTables,
    );
    return (value: x, y: y);
  }

  // --- Display labels (wire / index → complete string; unit included) ---

  /// Report-rate wire → display label (`1000 Hz`, …).
  String? reportRateWireToLabel(int wire) {
    final hz = reportRateWireToHz(wire);
    if (hz == null) return null;
    return '$hz Hz';
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
  /// Delegates to [KeyvalueTable.keyComboToLabel].
  String keyComboToLabel(int p1, int p2, int p3) =>
      keyvalues.keyComboToLabel(p1, p2, p3);

  /// Keyvalue byte → key name.
  ///
  /// Delegates to [KeyvalueTable.keyValueToLabel].
  String keyValueToLabel(int value) => keyvalues.keyValueToLabel(value);

  // --- Telink config field maps (data reference) → labels ---

  static const int _triOn = 0xFF;
  static const int _triOff = 0x0F;
  static const int _triIgnore = 0x00;

  /// ON / OFF / Ignore wire → display label.
  ///
  /// `0xFF`→`On`, `0x0F`→`Off`, `0x00`/other → null (ignore / unknown).
  String? triStateWireToLabel(int wire) {
    switch (wire & 0xFF) {
      case _triOn:
        return 'On';
      case _triOff:
        return 'Off';
      case _triIgnore:
      default:
        return null;
    }
  }

  /// Domain bool → ON / OFF wire byte for config SETs.
  ///
  /// Inverse of [triStateWireToBool]. Never emits `0x00` — "ignore" is a read
  /// state, not something the host writes.
  int triStateBoolToWire(bool on) => on ? _triOn : _triOff;

  /// ON / OFF / Ignore wire → bool for domain / controls.
  ///
  /// Display path: [triStateWireToLabel].
  bool? triStateWireToBool(int wire) {
    switch (wire & 0xFF) {
      case _triOn:
        return true;
      case _triOff:
        return false;
      case _triIgnore:
      default:
        return null;
    }
  }

  /// Button debounce index → display label.
  /// Generic wire→label lookup using catalog [OptionPair]s (debounce, sleep).
  ///
  /// Returns null if the wire is not in [options].
  ///
  /// Mirrors [lodWireToMm] / [angleTuneWireToLabel]: L5 owns the lookup logic,
  /// L2 owns the per-mouse mapping. Per SDRD "codec does not hardcode
  /// conversion parameters; depends on Layer 2".
  String? optionPairWireToLabel(int wire, List<OptionPair> options) {
    for (final opt in options) {
      if (opt.wire == (wire & 0xFF)) {
        return opt.label;
      }
    }
    return null;
  }

  ///
  /// `0x00`/`0x01`→`2ms` … `0x06`→`12ms`.
  String? debounceIndexToLabel(int index) {
    switch (index & 0xFF) {
      case 0x00:
      case 0x01:
        return '2ms';
      case 0x02:
        return '4ms';
      case 0x03:
        return '6ms';
      case 0x04:
        return '8ms';
      case 0x05:
        return '10ms';
      case 0x06:
        return '12ms';
      default:
        return null;
    }
  }

  /// Sleep / RGB-sleep index → display label (same table).
  ///
  /// Sheet wording: `30 sec`, `1 min` … `30 min`.
  String? sleepIndexToLabel(int index) {
    switch (index & 0xFF) {
      case 0x00:
        return '30 sec';
      case 0x01:
        return '1 min';
      case 0x02:
        return '2 min';
      case 0x03:
        return '5 min';
      case 0x04:
        return '10 min';
      case 0x05:
        return '15 min';
      case 0x06:
        return '30 min';
      default:
        return null;
    }
  }

  /// Angle-tune wire → display label using the catalog's per-mouse options.
  ///
  /// `wire` is the device byte; the label comes from the matching
  /// [AngleTuneOption]. Returns null if the wire is not in [options].
  ///
  /// The options come from the mouse catalog (not this codec) so the same
  /// sensor can be discrete on one mouse and (future) range on another.
  String? angleTuneWireToLabel(int wire, List<AngleTuneOption> options) {
    for (final opt in options) {
      if (opt.wire == (wire & 0xFF)) {
        return opt.label;
      }
    }
    return null;
  }

  /// PAW3395 lift-off distance level → display label.
  ///
  /// `0`→`1mm`, `1`→`2mm`.
  /// Generic LOD wire → display label using catalog options.
  ///
  /// Returns `null` if the wire is not in [options].
  ///
  /// Mirrors [angleTuneWireToLabel]: L5 owns wire→meaning, L2 owns the
  /// per-mouse options. The old fixed `0→1mm, 1→2mm` table was removed
  /// because it disagreed with the per-mouse catalog (e.g. wire 0 = 0.7mm).
  String? lodWireToLabel(int wire, List<LodOption> options) {
    for (final opt in options) {
      if (opt.wire == (wire & 0xFF)) {
        return '${_formatMm(opt.mm)}mm';
      }
    }
    return null;
  }

  /// `0.7` → `0.7`, `1.0` → `1` (drop trailing `.0`).
  static String _formatMm(double mm) {
    if (mm == mm.roundToDouble()) {
      return mm.toInt().toString();
    }
    return mm.toString();
  }

  /// Generic LOD wire → mm using catalog options.
  ///
  /// Returns null if wire not found in options.
  double? lodWireToMm(int wire, List<LodOption> options) {
    for (final opt in options) {
      if (opt.wire == (wire & 0xFF)) {
        return opt.mm;
      }
    }
    return null;
  }

  /// Generic LOD mm → wire using catalog options.
  ///
  /// Returns null if mm not found in options.
  int? lodMmToWire(double mm, List<LodOption> options) {
    for (final opt in options) {
      if (opt.mm == mm) {
        return opt.wire;
      }
    }
    return null;
  }

  /// RGB mode id → label.
  ///
  /// Authoritative per TelinkB80 Mouse Data Reference (Backlight Feature):
  /// 0x00 off, 0x01 constant, 0x02 multi color, 0x03 single breathing,
  /// 0x04 multi breathing, 0x05 running color, 0x06 cycle wave, 0x07 cycle color.
  String rgbModeToLabel(int mode) {
    switch (mode & 0xFF) {
      case 0x00:
        return 'Off';
      case 0x01:
        return 'Constant';
      case 0x02:
        return 'Multi color';
      case 0x03:
        return 'Single breathing';
      case 0x04:
        return 'Multi breathing';
      case 0x05:
        return 'Running color';
      case 0x06:
        return 'Cycle wave';
      case 0x07:
        return 'Cycle color';
      default:
        return 'Unknown RGB mode 0x${(mode & 0xFF).toRadixString(16)}';
    }
  }

  /// Brightness level index (0..4) → display label.
  ///
  /// `0`→`0%` … `4`→`100%`.
  String? brightnessLevelToLabel(int level) {
    switch (level & 0xFF) {
      case 0:
        return '0%';
      case 1:
        return '25%';
      case 2:
        return '50%';
      case 3:
        return '75%';
      case 4:
        return '100%';
      default:
        return null;
    }
  }

  /// Speed level index (0..4) → display label.
  ///
  /// `0`→`10%` … `4`→`100%`.
  String? speedLevelToLabel(int level) {
    switch (level & 0xFF) {
      case 0:
        return '10%';
      case 1:
        return '25%';
      case 2:
        return '50%';
      case 3:
        return '75%';
      case 4:
        return '100%';
      default:
        return null;
    }
  }

  /// Config NAK reason byte → display text.
  String nakReasonToLabel(int reason) {
    switch (reason & 0xFF) {
      case 0x01:
        return 'Handshake required before GET/SET';
      case 0x02:
        return 'Unknown config address';
      case 0x03:
        return 'Opcode is not GET or SET';
      case 0x04:
        return 'Payload length mismatch';
      case 0x05:
        return 'Array index out of bounds';
      case 0x06:
        return 'CRC16 mismatch on SET';
      case 0xFF:
        return 'Config address not implemented on device';
      default:
        return 'NAK reason 0x${(reason & 0xFF).toRadixString(16).padLeft(2, '0')}';
    }
  }
}
