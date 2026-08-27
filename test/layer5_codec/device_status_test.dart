import 'dart:typed_data';

import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:driver_hub/layer5_codec/protocol_transport.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockTransport implements ProtocolTransport {
  final Uint8List response;
  Uint8List? lastSentData;

  _MockTransport(this.response);

  @override
  Future<Uint8List> sendAndWait({
    required Uint8List data,
    required int reportId,
    required int reportLength,
    required bool Function(Uint8List) match,
    Duration? timeout,
  }) async {
    lastSentData = data;
    if (match(response)) {
      return response;
    }
    throw StateError('Mock response did not match expected filter');
  }
}

void main() {
  const protocol = MouseProtocol();

  group('DeviceStatusResult', () {
    test('isAwake and isAsleep getters work correctly', () {
      final awake = DeviceStatusResult(
        statusCode: 0x01,
        isAwake: true,
        raw: Uint8List(32),
      );
      expect(awake.isAwake, isTrue);
      expect(awake.isAsleep, isFalse);
      expect(awake.statusCode, 0x01);
      expect(awake.toString(), contains('isAwake=true'));

      final asleep = DeviceStatusResult(
        statusCode: 0x00,
        isAwake: false,
        raw: Uint8List(32),
      );
      expect(asleep.isAwake, isFalse);
      expect(asleep.isAsleep, isTrue);
      expect(asleep.statusCode, 0x00);
      expect(asleep.toString(), contains('isAwake=false'));
    });
  });

  group('MouseProtocol.parseDeviceStatus', () {
    test('parses desktop-prefixed awake frame', () {
      final raw = Uint8List(32);
      raw[0] = 0x07; // Report ID
      raw[1] = 0xA3; // Opcode
      raw[4] = 0x00; // Addrs / Len
      raw[5] = 0x01; // Len
      raw[6] = 0x01; // Byte 5 (after strip) is 0x01 = Awake
      final parsed = protocol.parseDeviceStatus(raw);
      expect(parsed, isNotNull);
      expect(parsed!.isAwake, isTrue);
      expect(parsed.isAsleep, isFalse);
      expect(parsed.statusCode, 0x01);
    });

    test('parses web bare asleep frame', () {
      final raw = Uint8List(32);
      raw[0] = 0xA3; // Opcode
      raw[4] = 0x01; // Len
      raw[5] = 0x00; // Byte 5 = 0x00 = Asleep
      final parsed = protocol.parseDeviceStatus(raw);
      expect(parsed, isNotNull);
      expect(parsed!.isAwake, isFalse);
      expect(parsed.isAsleep, isTrue);
      expect(parsed.statusCode, 0x00);
    });

    test('returns null on non-matching opcode', () {
      final raw = Uint8List(32);
      raw[0] = 0x07;
      raw[1] = 0xA4; // Battery opcode
      expect(protocol.parseDeviceStatus(raw), isNull);
    });

    test('returns null on empty payload', () {
      expect(protocol.parseDeviceStatus(Uint8List(0)), isNull);
    });
  });

  group('MouseProtocol.queryDeviceStatus', () {
    test('sends 32-byte 0xA3 ask frame and parses awake ACK', () async {
      final ack = Uint8List(32);
      ack[0] = 0x07;
      ack[1] = 0xA3;
      ack[6] = 0x01; // Awake

      final transport = _MockTransport(ack);
      final result = await protocol.queryDeviceStatus(transport);

      expect(transport.lastSentData, isNotNull);
      expect(transport.lastSentData![0], 0xA3);
      expect(transport.lastSentData!.length, 32);
      expect(result.isAwake, isTrue);
      expect(result.statusCode, 0x01);
    });

    test('sends 32-byte 0xA3 ask frame and parses asleep ACK', () async {
      final ack = Uint8List(32);
      ack[0] = 0xA3;
      ack[5] = 0x00; // Asleep

      final transport = _MockTransport(ack);
      final result = await protocol.queryDeviceStatus(transport);

      expect(result.isAwake, isFalse);
      expect(result.isAsleep, isTrue);
      expect(result.statusCode, 0x00);
    });
  });
}
