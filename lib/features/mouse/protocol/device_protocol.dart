import 'package:driver_hub/core/device/device_type.dart';
import 'package:driver_hub/core/device/hid_session.dart';
import 'package:flutter/foundation.dart';

/// Handshake result: the device type and id reported by the device.
class DeviceHandshake {
  /// Device type reported by the device, parsed from its wire byte.
  final DeviceType? deviceType;

  /// Device id reported by the device, comparable to the catalog `devId`.
  final String deviceId;

  const DeviceHandshake({required this.deviceType, required this.deviceId});
}

/// Battery query result: charge level and charging state.
class BatteryResult {
  /// 0..100, or -1 when unknown.
  final int percent;
  final bool isCharging;
  const BatteryResult({required this.percent, required this.isCharging});
}

/// Firmware query result: mouse and dongle version bytes (A8 reply).
class FirmwareResult {
  /// 4 mouse-firmware bytes (ack[5..8]).
  final List<int> mouseVersion;
  /// 4 dongle-firmware bytes (ack[9..12]).
  final List<int> dongleVersion;
  const FirmwareResult(
      {required this.mouseVersion, required this.dongleVersion});

  /// Best-guess formatted string until the real reply confirms the format.
  String get mouseVersionLabel => mouseVersion.join('.');
  String get dongleVersionLabel => dongleVersion.join('.');
}

/// Mouse handshake protocol. One protocol for all mice.
abstract class DeviceProtocol {
  Future<DeviceHandshake> handshake(HidSession session);
  Future<BatteryResult> queryBattery(HidSession session);
  Future<FirmwareResult> queryFirmware(HidSession session);
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
  static const int _batteryOpcode = 0xA4;
  static const int _firmwareOpcode = 0xA8;

  // Payload offsets (report id stripped). hid_tool keeps the report id on
  // desktop and drops it on web (WebHID oninputreport has no report id prefix).
  static const int _ackOpcodeOffset = 0;
  static const int _ackDeviceTypeOffset = 5;
  static const int _ackDeviceIdOffset = 6;
  static const int _deviceIdLength = 4;

  // A4 battery ack offsets (report id stripped).
  static const int _batteryPercentOffset = 5; // 0..100
  static const int _batteryChargingOffset = 6; // 0x01 charging, 0x00 not

  // A8 firmware ack offsets (report id stripped). len=8: 4 mouse + 4 dongle.
  static const int _firmwareMouseOffset = 5;
  static const int _firmwareDongleOffset = 9;
  static const int _firmwareVersionLength = 4;

  static const Duration _sendTimeout = Duration(milliseconds: 1000);

  @override
  Future<DeviceHandshake> handshake(HidSession session) {
    // receive then send in one enqueue (web drops ack if no listener yet).
    return session.enqueue(() async {
      final ask = _buildAskFrame();
      final ackFuture =
          session.receiveReport(_frameLength, timeout: _sendTimeout);
      debugPrint('[proto] handshake: sending ask ${_hex(ask)}');
      await session.sendReport(ask, reportId: _reportId);

      final ack = await ackFuture;
      debugPrint(
          '[proto] handshake: received ack ${_hex(ack)} (${ack.length}B)');

      final result = _parseAck(ack);
      debugPrint('[proto] handshake: deviceType=${result.deviceType} '
          'deviceId="${result.deviceId}"');
      return result;
    });
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

  DeviceHandshake _parseAck(Uint8List raw) {
    // Desktop prefixes the report id; web does not. Strip it so the payload
    // always starts at the opcode (matches the WebHID oninputreport shape).
    final ack = raw.isNotEmpty && raw[0] == _reportId
        ? Uint8List.fromList(raw.sublist(1))
        : raw;
    if (ack.length < _ackDeviceIdOffset + _deviceIdLength) {
      throw FormatException('Handshake ack too short: ${ack.length} bytes');
    }
    final opcode = ack[_ackOpcodeOffset];
    if (opcode != _ackOpcode) {
      throw FormatException(
        'Unexpected handshake ack opcode: 0x${opcode.toRadixString(16)}',
      );
    }
    final idBytes =
        ack.sublist(_ackDeviceIdOffset, _ackDeviceIdOffset + _deviceIdLength);
    return DeviceHandshake(
      deviceType: DeviceType.fromCode(ack[_ackDeviceTypeOffset]),
      deviceId: idBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );
  }

  @override
  Future<BatteryResult> queryBattery(HidSession session) {
    return session.enqueue(() async {
      final ask = _buildBatteryFrame();
      final ackFuture =
          session.receiveReport(_frameLength, timeout: _sendTimeout);
      debugPrint('[proto] battery: sending ask ${_hex(ask)}');
      await session.sendReport(ask, reportId: _reportId);

      final ack = await ackFuture;
      debugPrint(
          '[proto] battery: received ack ${_hex(ack)} (${ack.length}B)');
      return _parseBattery(ack);
    });
  }

  Uint8List _buildBatteryFrame() {
    final frame = Uint8List(_frameLength); // 32 bytes, all 00
    frame[0] = _batteryOpcode; // A4, report id 7, rest 00 — no CRC
    return frame;
  }

  BatteryResult _parseBattery(Uint8List raw) {
    final ack = raw.isNotEmpty && raw[0] == _reportId
        ? Uint8List.fromList(raw.sublist(1))
        : raw;
    if (ack.isEmpty) {
      throw FormatException('Battery ack empty');
    }
    final opcode = ack[0];
    if (opcode != _batteryOpcode) {
      throw FormatException(
        'Unexpected battery ack opcode: 0x${opcode.toRadixString(16)}',
      );
    }
    if (ack.length <= _batteryChargingOffset) {
      throw FormatException('Battery ack too short: ${ack.length} bytes');
    }
    final percent = ack[_batteryPercentOffset];
    final isCharging = ack[_batteryChargingOffset] != 0;
    return BatteryResult(percent: percent, isCharging: isCharging);
  }

  @override
  Future<FirmwareResult> queryFirmware(HidSession session) {
    return session.enqueue(() async {
      final ask = _buildFirmwareFrame();
      final ackFuture =
          session.receiveReport(_frameLength, timeout: _sendTimeout);
      debugPrint('[proto] firmware: sending ask ${_hex(ask)}');
      await session.sendReport(ask, reportId: _reportId);

      final ack = await ackFuture;
      debugPrint(
          '[proto] firmware: received ack ${_hex(ack)} (${ack.length}B)');
      return _parseFirmware(ack);
    });
  }

  Uint8List _buildFirmwareFrame() {
    final frame = Uint8List(_frameLength); // 32 bytes, all 00
    frame[0] = _firmwareOpcode; // A8, report id 7, rest 00 — no CRC
    return frame;
  }

  FirmwareResult _parseFirmware(Uint8List raw) {
    final ack = raw.isNotEmpty && raw[0] == _reportId
        ? Uint8List.fromList(raw.sublist(1))
        : raw;
    if (ack.isEmpty) {
      throw FormatException('Firmware ack empty');
    }
    final opcode = ack[0];
    if (opcode != _firmwareOpcode) {
      throw FormatException(
        'Unexpected firmware ack opcode: 0x${opcode.toRadixString(16)}',
      );
    }
    final end = _firmwareDongleOffset + _firmwareVersionLength; // 9+4=13
    if (ack.length < end) {
      throw FormatException('Firmware ack too short: ${ack.length} bytes');
    }
    final mouse = ack.sublist(
        _firmwareMouseOffset, _firmwareMouseOffset + _firmwareVersionLength);
    final dongle = ack.sublist(
        _firmwareDongleOffset, _firmwareDongleOffset + _firmwareVersionLength);
    return FirmwareResult(mouseVersion: mouse, dongleVersion: dongle);
  }

  String _hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}
