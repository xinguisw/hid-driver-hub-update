import 'dart:typed_data';

import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MouseProtocol.buildButtonMappingSetFrame', () {
    test('SET 0x08 addrs B2 len 24 + CRC matches payload', () {
      // Identity-shaped slots from live B2 capture (params may be product-specific).
      final buttons = [
        const ButtonMappingEntry(action: 0x02, param1: 0, param2: 0, param3: 0),
        const ButtonMappingEntry(action: 0x03, param1: 0, param2: 0, param3: 0),
        const ButtonMappingEntry(action: 0x04, param1: 0, param2: 0, param3: 0),
        const ButtonMappingEntry(action: 0x12, param1: 0x04, param2: 0, param3: 0),
        const ButtonMappingEntry(action: 0x12, param1: 0x05, param2: 0, param3: 0),
        const ButtonMappingEntry(action: 0x0E, param1: 0, param2: 0, param3: 0),
      ];
      final frame = MouseProtocol.buildButtonMappingSetFrame(buttons);
      expect(frame.length, 32);
      expect(frame[0], 0x08); // SET
      expect(frame[3], 0xB2);
      expect(frame[4], 24);
      expect(frame.sublist(5, 29), [
        0x02, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00,
        0x04, 0x00, 0x00, 0x00, 0x12, 0x04, 0x00, 0x00,
        0x12, 0x05, 0x00, 0x00, 0x0E, 0x00, 0x00, 0x00,
      ]);
      // CRC over data[24] only — same path as ack verify.
      expect(
        () => MouseProtocol.verifyConfigAckCrc(frame, label: 'buttonMapping'),
        returnsNormally,
      );
    });

    test('wrong slot count throws', () {
      expect(
        () => MouseProtocol.buildButtonMappingSetFrame(const [
          ButtonMappingEntry(action: 0x02, param1: 0, param2: 0, param3: 0),
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('factory identity actions CRC-stable', () {
      // Caps-aware product identity: L/R/M/Fwd/Back/DPI cycle (TranslationCodec).
      final buttons = [
        for (final a in [0x02, 0x03, 0x04, 0x05, 0x06, 0x0E])
          ButtonMappingEntry(action: a, param1: 0, param2: 0, param3: 0),
      ];
      final frame = MouseProtocol.buildButtonMappingSetFrame(buttons);
      expect(frame[0], 0x08);
      expect(frame[3], 0xB2);
      expect(
        () => MouseProtocol.verifyConfigAckCrc(frame),
        returnsNormally,
      );
      // Round-trip: desktop-prefixed raw still verifies.
      final desktop = Uint8List(33);
      desktop[0] = 0x07;
      desktop.setRange(1, 33, frame);
      expect(
        () => MouseProtocol.verifyConfigAckCrc(desktop),
        returnsNormally,
      );
    });
  });
}
