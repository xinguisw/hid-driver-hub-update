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

  /// PAW3395 angle-tune wire → display label.
  ///
  /// `0x00`→`-30°` … `0x04`→`30°`.
  String? angleTuneWireToLabel(int wire) {
    switch (wire & 0xFF) {
      case 0x00:
        return '-30°';
      case 0x01:
        return '-10°';
      case 0x02:
        return '0°';
      case 0x03:
        return '10°';
      case 0x04:
        return '30°';
      default:
        return null;
    }
  }

  /// PAW3395 lift-off distance level → display label.
  ///
  /// `0`→`1mm`, `1`→`2mm`.
  String? lodWireToLabel(int wire) {
    switch (wire & 0xFF) {
      case 0:
        return '1mm';
      case 1:
        return '2mm';
      default:
        return null;
    }
  }

  /// RGB mode id → label.
  // todo: still not confirm the value , so use the stale value for now
  String rgbModeToLabel(int mode) {
    switch (mode & 0xFF) {
      case 0x00:
        return 'Close';
      case 0x01:
        return 'Constant';
      case 0x02:
        return 'Single breathing';
      case 0x03:
        return 'Sunning color';
      case 0x04:
        return '7 Cycle color';
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
