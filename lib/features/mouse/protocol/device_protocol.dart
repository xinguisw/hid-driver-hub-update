import 'package:driver_hub/core/device/hid_session.dart';
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

/// Standard mouse protocol. 32-byte frame over report id 7.
///
/// Body layout: [opcode][r][r][r][addrs][len][data…][CRC lo][CRC hi].
/// hid_tool prefixes the report id, so the body starts with the opcode.
class MouseProtocol implements DeviceProtocol {
  const MouseProtocol();

  static const int _reportId = 0x07;
  static const int _frameLength = 32;
  static const int _askOpcode = 0xA1;
  static const int _ackOpcode = 0xA1;

  static const int _ackDeviceTypeOffset = 6;
  static const int _ackDeviceIdOffset = 7;
  static const int _deviceIdLength = 4;

  static const Duration _sendTimeout = Duration(milliseconds: 1000);
  static const Duration _postSendDelay = Duration(milliseconds: 5);

  @override
  Future<DeviceHandshake> handshake(HidSession session) async {
    final ask = _buildAskFrame();
    debugPrint('[proto] handshake: sending ask ${_hex(ask)}');
    await session.sendReport(ask, reportId: _reportId);
    await Future.delayed(_postSendDelay);

    final ack = await session
        .receiveReport(_frameLength, timeout: _sendTimeout)
        .timeout(_sendTimeout);
    debugPrint('[proto] handshake: received ack ${_hex(ack)} (${ack.length}B)');

    final result = _parseAck(ack);
    debugPrint('[proto] handshake: deviceType=${result.deviceType} '
        'deviceId="${result.deviceId}"');
    return result;
  }

  Uint8List _buildAskFrame() {
    final frame = Uint8List(_frameLength);
    frame[0] = _askOpcode;
    frame[5] = 0x01;
    frame[6] = 0xAA;
    frame[7] = 0x4E;
    frame[8] = 0xCD;
    frame[9] = 0x01;
    // Handshake is a fixed probe; CRC field stays zero per firmware contract.
    return frame;
  }

  DeviceHandshake _parseAck(Uint8List ack) {
    if (ack.length < _ackDeviceIdOffset + _deviceIdLength) {
      throw FormatException('Handshake ack too short: ${ack.length} bytes');
    }
    final opcode = ack[1];
    if (opcode != _ackOpcode) {
      throw FormatException(
        'Unexpected handshake ack opcode: 0x${opcode.toRadixString(16)}',
      );
    }
    // receiveReport includes the report id at [0]; the id sits at [7..10].
    final idBytes = ack.sublist(_ackDeviceIdOffset, _ackDeviceIdOffset + _deviceIdLength);
    return DeviceHandshake(
      deviceType: ack[_ackDeviceTypeOffset],
      deviceId: idBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );
  }

  String _hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}
