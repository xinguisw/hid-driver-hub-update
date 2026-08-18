import 'dart:typed_data';

import 'package:driver_hub/layer5_codec/codecs/osd_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = OsdCodec();

  group('OsdCodec.parsePerformance', () {
    test('new format: desktop capture decodes report rate, DPI stage, and DPI value', () {
      // 0x09, opcode 0x01, reportRateWire 0x01, dpiLevel 0x02, dpiHigh 0x03, dpiLow 0x20
      final raw = Uint8List.fromList([0x09, 0x01, 0x01, 0x02, 0x03, 0x20, 0, 0]);
      final result = codec.parsePerformance(raw);

      expect(result, isNotNull);
      expect(result!.reportRateWire, 0x01);
      expect(result.dpiLevel, 0x02);
      expect(result.dpiValue, 800);
    });

    test('legacy format: 0x09 0x01 0x00 reserved byte decodes dpiLevel before report rate', () {
      // 0x09, opcode 0x01, reserved 0x00, dpiLevel 0x02, reportRateWire 0x01
      final raw = Uint8List.fromList([0x09, 0x01, 0x00, 0x02, 0x01, 0, 0, 0]);
      final result = codec.parsePerformance(raw);

      expect(result, isNotNull);
      expect(result!.reportRateWire, 0x01);
      expect(result.dpiLevel, 0x02);
      expect(result.dpiValue, isNull);
    });

    test('web-style body decodes without report id', () {
      // opcode 0x01, reportRateWire 0x02, dpiLevel 0x03, dpiHigh 0x06, dpiLow 0x40
      final raw = Uint8List.fromList([0x01, 0x02, 0x03, 0x06, 0x40, 0, 0, 0]);
      final result = codec.parsePerformance(raw);

      expect(result, isNotNull);
      expect(result!.reportRateWire, 0x02);
      expect(result.dpiLevel, 0x03);
      expect(result.dpiValue, 1600);
    });

    test('webhid 31-byte padded unsolicited report decodes correctly', () {
      final raw = Uint8List.fromList([
        0x01, 0x01, 0x02, 0x03, 0x20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      ]);
      final result = codec.parsePerformance(raw);

      expect(result, isNotNull);
      expect(result!.reportRateWire, 0x01);
      expect(result.dpiLevel, 0x02);
      expect(result.dpiValue, 800);
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

    test('web-style report id 1 prefixed battery report', () {
      final raw = Uint8List.fromList([0x01, 0x02, 0x00, 0x50, 0x01, 0, 0, 0]);
      final b = codec.parseBattery(raw);
      expect(b, isNotNull);
      expect(b!.percent, 0x50);
      expect(b.isCharging, isTrue);
    });

    test('webhid 31-byte padded battery report', () {
      final raw = Uint8List.fromList([
        0x02, 0x00, 0x4B, 0x01, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      ]);
      final b = codec.parseBattery(raw);
      expect(b, isNotNull);
      expect(b!.percent, 75);
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
