import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirmwareResult.formatFirmwareVersion', () {
    test('2-byte MS version [Lo, Hi] displays as Hi.Lo', () {
      // Mouse structure A8 ack: [MS Lo][MS Hi]. Wire [0x04, 0x03] -> "3.4".
      expect(
        FirmwareResult.formatFirmwareVersion(const [0x04, 0x03]),
        '3.4',
      );
    });

    test('empty returns empty string', () {
      expect(FirmwareResult.formatFirmwareVersion(const []), '');
    });

    test('zero bytes display as 0.0', () {
      expect(FirmwareResult.formatFirmwareVersion(const [0x00, 0x00]), '0.0');
    });
  });
}
