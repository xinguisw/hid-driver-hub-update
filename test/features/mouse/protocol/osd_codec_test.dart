import 'dart:typed_data';

import 'package:driver_hub/layer5_codec/codecs/osd_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = OsdCodec();

  group('OsdCodec.parsePerformance', () {
    test('desktop capture decodes DPI stage before report rate', () {
      final raw = Uint8List.fromList([0x09, 0x01, 0x00, 0x02, 0x01, 0, 0, 0]);
      final result = codec.parsePerformance(raw);

      expect(result, isNotNull);
      expect(result!.reportRateWire, 0x01);
      expect(result.dpiLevel, 0x02);
    });

    test('web-style body decodes without report id', () {
      final raw = Uint8List.fromList([0x01, 0x00, 0x03, 0x02, 0, 0, 0, 0]);
      final result = codec.parsePerformance(raw);

      expect(result, isNotNull);
      expect(result!.reportRateWire, 0x02);
      expect(result.dpiLevel, 0x03);
    });

    test('battery opcode is not performance', () {
      final raw = Uint8List.fromList([0x09, 0x02, 0, 80, 0, 0, 0, 0]);
      expect(codec.parsePerformance(raw), isNull);
    });
  });

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
