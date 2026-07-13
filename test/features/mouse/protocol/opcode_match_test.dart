import 'dart:typed_data';

import 'package:driver_hub/features/mouse/protocol/device_protocol.dart';
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
}
