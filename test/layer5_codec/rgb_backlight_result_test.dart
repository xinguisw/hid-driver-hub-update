import 'dart:typed_data';

import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the decoded E2 payload separate from the full HID response', () {
    final data = Uint8List.fromList(
      [0x02, 0x02, 0x02, 0xFF, 0xFF, 0x00, 0x04, 0x00],
    );
    final raw = Uint8List(32);

    final result = RgbBacklightResult(
      enable: data[0],
      mode: data[1],
      brightness: data[2],
      speed: data[3],
      r: data[4],
      g: data[5],
      b: data[6],
      sleepTime: data[7],
      data: data,
      raw: raw,
    );

    expect(result.data, data);
    expect(result.data, hasLength(8));
    expect(result.raw, hasLength(32));
  });
}
