import 'package:driver_hub/core/device/hid_session.dart';
import 'package:driver_hub/core/utils/crc16.dart';
import 'package:flutter/foundation.dart';

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
  static const int _askOpcode = 0xA1;
  static const int _ackOpcode = 0xA1;
  static const int _handshakeAddrs = 0xA1;
  static const int _ackDeviceTypeOffset = 6;
  static const int _ackDeviceIdOffset = 7;
  static const Crc16 _crc = Crc16();

  @override
  Future<DeviceHandshake> handshake(HidSession session) async {
    final ask = _buildAskFrame();
    debugPrint('[proto] handshake: sending C2 ask ${_hex(ask)}');
    await session.sendReport(ask, reportId: _reportId);

    final ack = await session.receiveReport(_frameLength);
    debugPrint('[proto] handshake: received ack ${_hex(ack)} (${ack.length}B)');

    final result = _parseAck(ack);
    debugPrint('[proto] handshake: deviceType=${result.deviceType} '
        'deviceId="${result.deviceId}" (byte=0x${ack[_ackDeviceIdOffset].toRadixString(16)})');
    return result;
  }

  Uint8List _buildAskFrame() {
    final frame = Uint8List(_frameLength);
    frame[0] = _reportId;
    frame[1] = _askOpcode;
    frame[4] = _handshakeAddrs;
    // CRC over bytes 0.._frameLength-3, little-endian at the last 2 bytes.
    final crc = _crc.bytes(Uint8List.fromList(frame.sublist(0, _frameLength - 2)));
    frame[_frameLength - 2] = crc[0];
    frame[_frameLength - 1] = crc[1];
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

  String _hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}
