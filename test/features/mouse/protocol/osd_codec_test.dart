import 'dart:typed_data';

import 'package:driver_hub/features/mouse/protocol/osd_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = OsdCodec();

  group('OsdCodec.parseBattery', () {
    test('desktop capture 09 02 00 64 01 → 100% charging', () {
      // Real device: report id 9, opcode 2, reserved 0, percent 0x64, chg 1.
      final raw = Uint8List.fromList([0x09, 0x02, 0x00, 0x64, 0x01, 0, 0, 0]);
      final b = codec.parseBattery(raw);
      expect(b, isNotNull);
      expect(b!.percent, 100);
      expect(b.isCharging, isTrue);
    });

    test('desktop capture 09 02 00 64 00 → 100% not charging', () {
      final raw = Uint8List.fromList([0x09, 0x02, 0x00, 0x64, 0x00, 0, 0, 0]);
      final b = codec.parseBattery(raw);
      expect(b, isNotNull);
      expect(b!.percent, 100);
      expect(b.isCharging, isFalse);
    });

    test('web-style 8-byte body same offsets after no report id', () {
      final raw = Uint8List.fromList([0x02, 0x00, 0x50, 0x01, 0, 0, 0, 0]);
      final b = codec.parseBattery(raw);
      expect(b, isNotNull);
      expect(b!.percent, 0x50);
      expect(b.isCharging, isTrue);
    });

    test('dpi opcode is not battery', () {
      final raw = Uint8List.fromList([0x09, 0x01, 0, 8, 3, 0, 0, 0]);
      expect(codec.parseBattery(raw), isNull);
    });

    test('rejects percent over 100', () {
      final raw = Uint8List.fromList([0x09, 0x02, 0x00, 0xFF, 0, 0, 0, 0]);
      expect(codec.parseBattery(raw), isNull);
    });
  });
}
