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
  /// Shortcut / consumer actions show `param1`/`param2` as raw bytes.
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
        return 'Shortcut (${_paramBytes(param1, param2, param3)})';
      case 0x13:
        return 'Consumer key (${_paramBytes(param1, param2, param3)})';
      case 0x14:
        return 'Macro play (#$param1)';
      default:
        return 'Unknown action 0x${action.toRadixString(16)} '
            '(p=$param1,$param2,$param3)';
    }
  }

  String _paramBytes(int p1, int p2, int p3) {
    final parts = <String>['0x${p1.toRadixString(16)}'];
    if (p2 != 0 || p3 != 0) {
      parts.add('0x${p2.toRadixString(16)}');
    }
    if (p3 != 0) {
      parts.add('0x${p3.toRadixString(16)}');
    }
    return parts.join(', ');
  }
}
