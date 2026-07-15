import 'dart:typed_data';

import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MouseProtocol.matchesOpcode', () {
    test('matches desktop-prefixed A4', () {
      final raw = Uint8List.fromList([0x07, 0xA4, 0, 0, 0, 0x64, 0x01]);
      expect(MouseProtocol.matchesOpcode(raw, 0xA4), isTrue);
      expect(MouseProtocol.matchesOpcode(raw, 0xA1), isFalse);
    });

    test('matches web body without report id', () {
      final raw = Uint8List.fromList([0xA8, 0, 0, 0, 0, 1, 2, 3, 4]);
      expect(MouseProtocol.matchesOpcode(raw, 0xA8), isTrue);
      expect(MouseProtocol.matchesOpcode(raw, 0xA4), isFalse);
    });

    test('noise is not a match', () {
      final noise = Uint8List.fromList([0x07, 0xFF, 0, 0]);
      expect(MouseProtocol.matchesOpcode(noise, 0xA1), isFalse);
      expect(MouseProtocol.matchesOpcode(noise, 0xA4), isFalse);
    });

    test('empty is not a match', () {
      expect(MouseProtocol.matchesOpcode(Uint8List(0), 0xA4), isFalse);
    });
  });

  group('MouseProtocol.stripReportId / matchesConfigAck', () {
    test('desktop GET reply keeps opcode after strip', () {
      // report id 07 + GET 07 + reserves + addrs B2
      final raw = Uint8List.fromList([
        0x07, 0x07, 0x00, 0x00, 0xB2, 0x18, 0x02, 0x00,
      ]);
      final body = MouseProtocol.stripReportId(raw);
      expect(body[0], 0x07);
      expect(body[3], 0xB2);
      expect(MouseProtocol.matchesConfigAck(raw, addrs: 0xB2), isTrue);
    });

    test('web GET reply does not strip opcode 0x07', () {
      // body starts with GET opcode 07, then reserve 00 (not a second opcode)
      final raw = Uint8List.fromList([
        0x07, 0x00, 0x00, 0xB2, 0x18, 0x02, 0x00, 0x00,
      ]);
      final body = MouseProtocol.stripReportId(raw);
      expect(body[0], 0x07);
      expect(body[3], 0xB2);
      expect(MouseProtocol.matchesConfigAck(raw, addrs: 0xB2), isTrue);
    });

    test('web GET wrong addrs does not match', () {
      final raw = Uint8List.fromList([
        0x07, 0x00, 0x00, 0xB2, 0x18, 0x02, 0x00, 0x00,
      ]);
      expect(MouseProtocol.matchesConfigAck(raw, addrs: 0xC2), isFalse);
    });
  });
}
