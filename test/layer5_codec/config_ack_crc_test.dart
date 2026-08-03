import 'dart:typed_data';

import 'package:driver_hub/layer5_codec/codec_exception.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

/// Live M7XSE config ACKs (desktop: report id 0x07 + 31B body).
void main() {
  group('MouseProtocol.validateConfigAckFrame', () {
    test('B2 desktop length + addrs OK', () {
      expect(
        () => MouseProtocol.validateConfigAckFrame(
          _b2Desktop(),
          addrs: 0xB2,
        ),
        returnsNormally,
      );
    });

    test('B2 web body OK', () {
      final web = Uint8List.sublistView(_b2Desktop(), 1);
      expect(
        () => MouseProtocol.validateConfigAckFrame(web, addrs: 0xB2),
        returnsNormally,
      );
    });

    test('short body throws', () {
      expect(
        () => MouseProtocol.validateConfigAckFrame(
          Uint8List(8),
          addrs: 0xB2,
        ),
        throwsA(isA<CodecException>()),
      );
    });

    test('wrong addrs throws', () {
      expect(
        () => MouseProtocol.validateConfigAckFrame(
          _b2Desktop(),
          addrs: 0xC2,
        ),
        throwsA(isA<CodecException>()),
      );
    });

    test('NAK with matching addrs passes length/header', () {
      final raw = _b2Desktop();
      raw[1] = 0xFF;
      expect(
        () => MouseProtocol.validateConfigAckFrame(raw, addrs: 0xB2),
        returnsNormally,
      );
    });
  });

  group('MouseProtocol.verifyConfigAckCrc', () {
    test('B2 buttonMapping desktop MATCH', () {
      final raw = _b2Desktop();
      expect(() => MouseProtocol.verifyConfigAckCrc(raw), returnsNormally);
    });

    test('B2 buttonMapping web body (no report id) MATCH', () {
      final web = Uint8List.sublistView(_b2Desktop(), 1);
      expect(() => MouseProtocol.verifyConfigAckCrc(web), returnsNormally);
    });

    test('C2 reportRateDpi MATCH (len 3 + zero pad)', () {
      final raw = _u8([
        0x07, 0x07, 0x00, 0x00, 0xc2, 0x03,
        0x01, 0x01, 0x1f,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
        0x44, 0xb3,
      ]);
      expect(() => MouseProtocol.verifyConfigAckCrc(raw), returnsNormally);
    });

    test('C4 dpiTable MATCH', () {
      final raw = _u8([
        0x07, 0x07, 0x00, 0x00, 0xc4, 0x10,
        0x13, 0x00, 0x26, 0x00, 0x39, 0x00, 0x55, 0x00,
        0xbe, 0x00, 0x26, 0x00, 0x26, 0x00, 0x26, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0xb1, 0xe9,
      ]);
      expect(() => MouseProtocol.verifyConfigAckCrc(raw), returnsNormally);
    });

    test('C6 dpiRgb MATCH', () {
      final raw = _u8([
        0x07, 0x07, 0x00, 0x00, 0xc6, 0x18,
        0x64, 0x00, 0x00, 0x00, 0x00, 0x64, 0x00, 0x64,
        0x00, 0x64, 0x64, 0x00, 0x64, 0x00, 0x64, 0x00,
        0x64, 0x64, 0x64, 0x32, 0x00, 0x64, 0x64, 0x64,
        0xed, 0xdb,
      ]);
      expect(() => MouseProtocol.verifyConfigAckCrc(raw), returnsNormally);
    });

    test('D4 sensorOther MATCH', () {
      final raw = _u8([
        0x07, 0x07, 0x00, 0x00, 0xd4, 0x0e,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x04, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00,
        0x8b, 0x38,
      ]);
      expect(() => MouseProtocol.verifyConfigAckCrc(raw), returnsNormally);
    });

    test('E2 NAK still has valid CRC', () {
      final raw = _u8([
        0x07, 0xff, 0x00, 0x00, 0xe2, 0x01,
        0xff,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x0a, 0xf0,
      ]);
      expect(() => MouseProtocol.verifyConfigAckCrc(raw), returnsNormally);
    });

    test('mismatch throws', () {
      final raw = _b2Desktop();
      raw[30] = 0x00;
      raw[31] = 0x00;
      expect(
        () => MouseProtocol.verifyConfigAckCrc(raw, label: 'buttonMapping'),
        throwsA(isA<CodecException>()),
      );
    });
  });
}

Uint8List _u8(List<int> bytes) => Uint8List.fromList(bytes);

Uint8List _b2Desktop() => _u8([
      0x07, 0x07, 0x00, 0x00, 0xb2, 0x18,
      0x02, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00,
      0x04, 0x00, 0x00, 0x00, 0x12, 0x04, 0x00, 0x00,
      0x12, 0x05, 0x00, 0x00, 0x0e, 0x00, 0x00, 0x00,
      0x7f, 0x58,
    ]);
