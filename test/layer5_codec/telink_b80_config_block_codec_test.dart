import 'package:driver_hub/layer5_codec/codecs/telink_b80_config_block_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('patches only documented D4 Sensor/Other byte positions', () {
    final source = List<int>.generate(18, (index) => index);

    final patched = TelinkB80ConfigBlockCodec.patchSensorOther(
      source,
      rippleEnabled: true,
      angleSnapEnabled: false,
      lodWire: 4,
      angleTuneEnabled: true,
      angleTuneWire: 3,
      performanceWire: 2,
      debounceWire: 6,
      sleepWire: 5,
      wheelInvert: false,
    );

    expect(patched, [
      0xFF,
      1,
      0x0F,
      3,
      4,
      5,
      0xFF,
      3,
      8,
      2,
      10,
      11,
      12,
      6,
      14,
      5,
      16,
      0x0F,
    ]);
    expect(source, List<int>.generate(18, (index) => index));
  });

  test('encodes the complete documented E2 RGB-backlight block', () {
    expect(
      TelinkB80ConfigBlockCodec.encodeRgbBacklight(
        modeId: 2,
        brightness: 3,
        speed: 4,
        red: 5,
        green: 6,
        blue: 7,
        sleepWire: 8,
      ),
      [2, 3, 4, 5, 6, 7, 8, 0x00],
    );
  });

  test('patches only staged E2 fields and preserves unknown live bytes', () {
    final current = <int>[0x02, 0x02, 0xFF, 0xFF, 0x00, 0x04, 0x00, 0x00];

    final brightnessOnly = TelinkB80ConfigBlockCodec.patchRgbBacklight(
      current,
      brightness: 4,
    );

    expect(brightnessOnly, [0x02, 0x04, 0xFF, 0xFF, 0x00, 0x04, 0x00, 0x00]);
    expect(current, [0x02, 0x02, 0xFF, 0xFF, 0x00, 0x04, 0x00, 0x00]);
  });
}
