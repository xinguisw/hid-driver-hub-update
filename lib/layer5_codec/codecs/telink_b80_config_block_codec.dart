import 'dart:typed_data';

import 'translation_codec.dart';

/// Telink B80 configuration-block field codec.
///
/// Owns the documented D4 and E2 byte layouts. Callers supply semantic
/// values; they never select protocol byte offsets themselves.
class TelinkB80ConfigBlockCodec {
  const TelinkB80ConfigBlockCodec._();

  static const int sensorOtherLength = 18;
  static const int rgbBacklightLength = 8;

  /// Applies a semantic patch to the live D4 Sensor/Other block.
  ///
  /// Layout is from the Telink B80 mouse data structure: ripple[0],
  /// angle-snap[2], LOD[4], angle-tune enabled[6], angle value[7],
  /// performance[9], debounce[13], sleep[15], and wheel direction[17].
  static Uint8List patchSensorOther(
    List<int> current, {
    bool? rippleEnabled,
    bool? angleSnapEnabled,
    int? lodWire,
    bool? angleTuneEnabled,
    int? angleTuneWire,
    int? performanceWire,
    int? debounceWire,
    int? sleepWire,
    bool? wheelInvert,
  }) {
    if (current.length != sensorOtherLength) {
      throw ArgumentError.value(
        current.length,
        'current.length',
        'Telink B80 D4 block must be $sensorOtherLength bytes',
      );
    }
    final block = Uint8List.fromList(current);
    const translate = TranslationCodec();
    if (rippleEnabled != null) {
      block[0] = translate.triStateBoolToWire(rippleEnabled);
    }
    if (angleSnapEnabled != null) {
      block[2] = translate.triStateBoolToWire(angleSnapEnabled);
    }
    if (lodWire != null) block[4] = _byte(lodWire, 'lodWire');
    if (angleTuneEnabled != null) {
      block[6] = translate.triStateBoolToWire(angleTuneEnabled);
    }
    if (angleTuneWire != null) {
      block[7] = _byte(angleTuneWire, 'angleTuneWire');
    }
    if (performanceWire != null) {
      block[9] = _byte(performanceWire, 'performanceWire');
    }
    if (debounceWire != null) {
      block[13] = _byte(debounceWire, 'debounceWire');
    }
    if (sleepWire != null) block[15] = _byte(sleepWire, 'sleepWire');
    if (wheelInvert != null) {
      block[17] = translate.triStateBoolToWire(wheelInvert);
    }
    return block;
  }

  /// Applies a semantic patch to the live E2 RGB-backlight block.
  ///
  /// New layout: mode[0], brightness[1], speed[2], RGB[3..5], sleep time[6], reserved[7] (0x00).
  /// Unspecified fields remain exactly as read from the mouse.
  static Uint8List patchRgbBacklight(
    List<int> current, {
    int? modeId,
    int? brightness,
    int? speed,
    int? red,
    int? green,
    int? blue,
    int? sleepWire,
  }) {
    if (current.length != rgbBacklightLength) {
      throw ArgumentError.value(
        current.length,
        'current.length',
        'Telink B80 E2 block must be $rgbBacklightLength bytes',
      );
    }
    final block = Uint8List.fromList(current);
    if (modeId != null) block[0] = _byte(modeId, 'modeId');
    if (brightness != null) block[1] = _byte(brightness, 'brightness');
    if (speed != null) block[2] = _byte(speed, 'speed');
    if (red != null) block[3] = _byte(red, 'red');
    if (green != null) block[4] = _byte(green, 'green');
    if (blue != null) block[5] = _byte(blue, 'blue');
    if (sleepWire != null) block[6] = _byte(sleepWire, 'sleepWire');
    block[7] = 0x00;
    return block;
  }

  /// Builds the complete E2 RGB-backlight data block from semantic values.
  static Uint8List encodeRgbBacklight({
    required int modeId,
    required int brightness,
    required int speed,
    required int red,
    required int green,
    required int blue,
    required int sleepWire,
  }) {
    return Uint8List.fromList([
      _byte(modeId, 'modeId'),
      _byte(brightness, 'brightness'),
      _byte(speed, 'speed'),
      _byte(red, 'red'),
      _byte(green, 'green'),
      _byte(blue, 'blue'),
      _byte(sleepWire, 'sleepWire'),
      0x00,
    ]);
  }

  static int _byte(int value, String name) {
    if (value < 0 || value > 0xFF) {
      throw ArgumentError.value(value, name, 'must fit one byte');
    }
    return value;
  }
}
