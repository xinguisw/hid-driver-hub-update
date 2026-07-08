import 'dart:typed_data';

import 'package:driver_hub/core/device/hid_session.dart';

/// Handshake result: the device type and id reported by the device.
class DeviceHandshake {
  /// Device type reported by the device (e.g. 1 for mouse).
  final int deviceType;

  /// Device id reported by the device, comparable to the catalog `devId`.
  final String deviceId;

  const DeviceHandshake({required this.deviceType, required this.deviceId});
}

/// Mouse handshake protocol. One protocol for all mice.
abstract class DeviceProtocol {
  Future<DeviceHandshake> handshake(HidSession session);
}

/// Standard mouse protocol.
///
/// Report id 7, 32-byte frame: [reportId][opcode][r][r][addrs][len][data][CRC][CRC].
class MouseProtocol implements DeviceProtocol {
  const MouseProtocol();

  static const int _reportId = 0x07;
  static const int _frameLength = 32;
  static const int _askOpcode = 0xC2;
  static const int _ackOpcode = 0xA1;
  static const int _handshakeAddrs = 0xA1;
  static const int _ackDeviceTypeOffset = 6;
  static const int _ackDeviceIdOffset = 7;

  @override
  Future<DeviceHandshake> handshake(HidSession session) async {
    await session.sendReport(_buildAskFrame(), reportId: _reportId);
    final ack = await session.receiveReport(_frameLength);
    return _parseAck(ack);
  }

  Uint8List _buildAskFrame() {
    final frame = Uint8List(_frameLength);
    frame[0] = _reportId;
    frame[1] = _askOpcode;
    frame[4] = _handshakeAddrs;
    // frame[5] len = 0; CRC (30,31) zero — later implement
    return frame;
  }

  DeviceHandshake _parseAck(Uint8List ack) {
    if (ack.length < _ackDeviceIdOffset + 1) {
      throw FormatException('Handshake ack too short: ${ack.length} bytes');
    }
    final opcode = ack[1];
    if (opcode != _ackOpcode) {
      throw FormatException(
        'Unexpected handshake ack opcode: 0x${opcode.toRadixString(16)}',
      );
    }
    return DeviceHandshake(
      deviceType: ack[_ackDeviceTypeOffset],
      deviceId: ack[_ackDeviceIdOffset].toString(),
    );
  }
}
