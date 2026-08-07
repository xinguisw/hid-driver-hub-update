import 'dart:typed_data';

import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:driver_hub/layer5_codec/utils/crc16.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MouseProtocol.buildRgbBacklightSetFrame', () {
    test('SET 0x08 addrs E2 len 8 + CRC over 8 data bytes', () {
      // enable(0xFF on), mode, brightness, speed, R, G, B, sleepTime index.
      final block = Uint8List.fromList(
        [0xFF, 0x03, 0x04, 0x02, 0x12, 0x34, 0x56, 0x01],
      );
      final frame = MouseProtocol.buildRgbBacklightSetFrame(block);
      expect(frame.length, 32);
      expect(frame[0], 0x08); // SET
      expect(frame[3], 0xE2);
      expect(frame[4], 8);
      expect(
        frame.sublist(5, 13),
        [0xFF, 0x03, 0x04, 0x02, 0x12, 0x34, 0x56, 0x01],
      );
      // CRC16-Modbus over the 8 data bytes (offsets 5..12), stored at 13..14.
      // Matches the per-block SET pattern (setSensorOther CRCs its 18 bytes).
      final crc = const Crc16().bytes(Uint8List.fromList(frame.sublist(5, 13)));
      expect(frame[13], crc[0]);
      expect(frame[14], crc[1]);
    });

    test('wrong block length throws', () {
      expect(
        () => MouseProtocol.buildRgbBacklightSetFrame(
          Uint8List.fromList([0xFF, 0x03]),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('distinct blocks yield distinct CRCs (not vacuous)', () {
      final a = MouseProtocol.buildRgbBacklightSetFrame(
        Uint8List.fromList([0xFF, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
      );
      final b = MouseProtocol.buildRgbBacklightSetFrame(
        Uint8List.fromList([0xFF, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
      );
      expect(a.sublist(13, 15), isNot(equals(b.sublist(13, 15))));
    });
  });
}

