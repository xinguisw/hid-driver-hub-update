import 'device_type.dart';
import 'package:driver_hub/layer5_codec/codec_exception.dart';
import 'package:driver_hub/layer5_codec/button_mapping_wire_order.dart';
import 'package:driver_hub/layer5_codec/codecs/translation_codec.dart';
import 'package:driver_hub/layer5_codec/utils/crc16.dart';
import 'package:driver_hub/layer5_codec/macro_codec.dart';
import 'package:driver_hub/layer5_codec/protocol_transport.dart';
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
  /// 4 mouse-firmware bytes (ack[5..8]), wire order.
  final List<int> mouseVersion;

  /// 4 dongle-firmware bytes (ack[9..12]), wire order.
  final List<int> dongleVersion;
  const FirmwareResult({
    required this.mouseVersion,
    required this.dongleVersion,
  });

  /// Wire e.g. 04 03 02 01 → display "1.2.3.4" (little-endian version).
  String get mouseVersionLabel => formatFirmwareVersion(mouseVersion);
  String get dongleVersionLabel => formatFirmwareVersion(dongleVersion);

  /// Shared mouse / receiver path: reverse wire bytes, join with dots.
  static String formatFirmwareVersion(List<int> wire) {
    if (wire.isEmpty) return '';
    return wire.reversed.map((b) => b.toString()).join('.');
  }
}

// ---------------------------------------------------------------------------
// Onboard config GET results (report 7, opcode GET 0x07 / ack SET 0x08).
// Layout from Telink USB MOUSE CONFIG: body after report-id strip:
//   [0] opcode  [1] r  [2] r  [3] addrs  [4] len  [5..] data
// ---------------------------------------------------------------------------

/// One button: action + 3 params (4 bytes).
class ButtonMappingEntry {
  final int action;
  final int param1;
  final int param2;
  final int param3;
  const ButtonMappingEntry({
    required this.action,
    required this.param1,
    required this.param2,
    required this.param3,
  });

  @override
  String toString() =>
      'ButtonMappingEntry(action=$action, p1=$param1, p2=$param2, p3=$param3)';
}

/// addrs 0xB2 — button mapping (len 24 = 6 × 4).
class ButtonMappingResult {
  /// Entries in logical UI order: Left, Right, Middle, Forward, Backward, DPI.
  final List<ButtonMappingEntry> buttons;
  final Uint8List raw;
  const ButtonMappingResult({required this.buttons, required this.raw});
}

/// addrs 0xC2 — report rate & DPI info (len 3).
class ReportRateDpiInfoResult {
  final int reportRate;
  final int dpiCurrentLevel;
  final int dpiActiveLevel;
  final Uint8List raw;
  const ReportRateDpiInfoResult({
    required this.reportRate,
    required this.dpiCurrentLevel,
    required this.dpiActiveLevel,
    required this.raw,
  });

  @override
  String toString() =>
      'ReportRateDpiInfo(rate=$reportRate, currentLv=$dpiCurrentLevel, '
      'activeLv=$dpiActiveLevel)';
}

/// One DPI stage X/Y wire bytes (sensor encoding applied later).
class DpiTableEntry {
  final int x;
  final int y;
  const DpiTableEntry({required this.x, required this.y});

  @override
  String toString() => 'DpiTableEntry(x=$x, y=$y)';
}

/// addrs 0xC4 — DPI table (len 16 = 8 interleaved byte pairs).
class DpiTableResult {
  final List<DpiTableEntry> stages;

  /// Config data payload only (typically 16 bytes), for sensor decode.
  final Uint8List data;
  final Uint8List raw;
  const DpiTableResult({
    required this.stages,
    required this.data,
    required this.raw,
  });
}

/// One stage RGB.
class DpiRgbEntry {
  final int r;
  final int g;
  final int b;
  const DpiRgbEntry({required this.r, required this.g, required this.b});

  @override
  String toString() => 'DpiRgbEntry(r=$r, g=$g, b=$b)';
}

/// addrs 0xC6 — DPI RGB (len 24 = 8 × RGB).
class DpiRgbResult {
  final List<DpiRgbEntry> stages;
  final Uint8List raw;
  const DpiRgbResult({required this.stages, required this.raw});
}

/// addrs 0xD4 — sensor + other (len 14).
class SensorOtherResult {
  final int rippleControl;
  final int angleSnap;
  final int lod;
  final int angleTune;
  final int angleValue;
  final int performance;
  final int debounceTime;
  final int sleepTime;
  final int wheelDirection;

  /// Config data payload only (18 bytes), for read-before-write SETs.
  final Uint8List data;
  final Uint8List raw;
  const SensorOtherResult({
    required this.rippleControl,
    required this.angleSnap,
    required this.lod,
    required this.angleTune,
    required this.angleValue,
    required this.performance,
    required this.debounceTime,
    required this.sleepTime,
    required this.wheelDirection,
    required this.data,
    required this.raw,
  });

  @override
  String toString() =>
      'SensorOther(ripple=$rippleControl, angleSnap=$angleSnap, lod=$lod, '
      'angleTune=$angleTune, angleValue=$angleValue, perf=$performance, '
      'debounce=$debounceTime, sleep=$sleepTime, wheel=$wheelDirection)';
}

/// addrs 0xE2 — RGB backlight (len 8).
class RgbBacklightResult {
  final int enable;
  final int mode;
  final int brightness;
  final int speed;
  final int r;
  final int g;
  final int b;
  final int sleepTime;
  /// Decoded eight-byte E2 payload, kept separate from the full HID frame.
  final Uint8List data;
  final Uint8List raw;
  const RgbBacklightResult({
    required this.enable,
    required this.mode,
    required this.brightness,
    required this.speed,
    required this.r,
    required this.g,
    required this.b,
    required this.sleepTime,
    required this.data,
    required this.raw,
  });

  @override
  String toString() =>
      'RgbBacklight(en=$enable, mode=$mode, bri=$brightness, spd=$speed, '
      'rgb=($r,$g,$b), sleep=$sleepTime)';
}

/// Mouse protocol. One implementation for all mice (same firmware family).
abstract class DeviceProtocol {
  Future<DeviceHandshake> handshake(
    ProtocolTransport session, {
    required int deviceType,
    required String deviceId,
  });
  Future<BatteryResult> queryBattery(ProtocolTransport session);
  Future<FirmwareResult> queryFirmware(ProtocolTransport session);

  Future<ButtonMappingResult> queryButtonMapping(ProtocolTransport session);

  /// SET addrs 0xB2 — write full button map (6 × 4 + CRC). Chart encoding loop.
  /// [buttons] is supplied in logical UI order; the shared B2 slot permutation
  /// is applied before the wire frame and CRC are built.
  Future<void> setButtonMapping(
    ProtocolTransport session,
    List<ButtonMappingEntry> buttons,
  );

  /// SET addrs 0xC2 — write report rate block (3 bytes + CRC).
  ///
  /// [dataBlock] must be exactly 3 bytes:
  /// `[reportRateWire, dpiCurrentLevel, dpiActiveLevel]`.
  /// The device stores all three fields at this address; a partial write
  /// is rejected with NAK 0x04 (payload length mismatch).
  Future<void> setReportRate(ProtocolTransport session, Uint8List dataBlock);

  Future<ReportRateDpiInfoResult> queryReportRateDpiInfo(
    ProtocolTransport session,
  );
  Future<DpiTableResult> queryDpiTable(ProtocolTransport session);

  /// SET addrs 0xC4 — write the DPI table (16 bytes, 8 stages × 2 bytes + CRC).
  ///
  /// [dataBlock] must be exactly 16 bytes of wire-encoded DPI stage values.
  Future<void> setDpiTable(ProtocolTransport session, Uint8List dataBlock);

  Future<DpiRgbResult> queryDpiRgb(ProtocolTransport session);

  /// SET addrs 0xC6 — write the DPI RGB block (24 bytes, 8 stages × R,G,B + CRC).
  ///
  /// [dataBlock] must be exactly 24 bytes of R,G,B per stage.
  Future<void> setDpiRgb(ProtocolTransport session, Uint8List dataBlock);

  Future<SensorOtherResult> querySensorOther(ProtocolTransport session);

  /// SET addrs 0xD4 — write sensor/other block (18 bytes + CRC).
  ///
  /// [dataBlock] must be exactly 18 bytes:
  /// `[ripple(0), res(1), angleSnap(2), res(3), lod(4), res(5), angleTune(6),
  /// angleValue(7), res(8), performance(9), res(10..12), debounce(13), res(14),
  /// sleep(15), res(16), wheel(17)]`.
  /// The device stores all fields at this address; a partial write
  /// is rejected with NAK 0x04 (payload length mismatch).
  Future<void> setSensorOther(ProtocolTransport session, Uint8List dataBlock);

  Future<RgbBacklightResult> queryRgbBacklight(ProtocolTransport session);

  /// SET addrs 0xE2 — write RGB backlight block (8 bytes + CRC).
  ///
  /// [dataBlock] must be exactly 8 bytes:
  /// `[enable(0), mode(1), brightness(2), speed(3), r(4), g(5), b(6),
  /// sleepTime(7)]`.
  /// `enable` is tri-state (0xFF on / 0x0F off); `brightness`/`speed` are level
  /// indices; `sleepTime` is an index into the catalog's `sleepTimeOptions`.
  Future<void> setRgbBacklight(ProtocolTransport session, Uint8List dataBlock);

  /// Write one macro through the dedicated three-chunk report-8 transfer.
  Future<void> setMacro(
    ProtocolTransport session,
    MacroTransferDefinition macro,
  );
}

/// Standard mouse protocol. 32-byte frame over report id 7.
///
/// Body layout: [opcode][r][r][addrs][len][data…][CRC lo][CRC hi].
/// hid_tool may prefix the report id (desktop); strip before parse.
class MouseProtocol implements DeviceProtocol {
  const MouseProtocol();

  static const int _reportId = 0x07;
  static const int _frameLength = 32;
  static const int _askOpcode = 0xA1;
  static const int _ackOpcode = 0xA1;
  static const int _batteryOpcode = 0xA4;
  static const int _firmwareOpcode = 0xA8;

  /// GET / SET (ack) / NAK — USB MOUSE CONFIG sheet.
  static const int _getOpcode = 0x07;
  static const int _setOpcode = 0x08;
  static const int _nakOpcode = 0xFF;

  /// Onboard block addresses.
  static const int addrsButtonMapping = 0xB2;
  static const int addrsReportRateDpi = 0xC2;
  static const int addrsDpiTable = 0xC4;
  static const int addrsDpiRgb = 0xC6;
  static const int addrsSensorOther = 0xD4;
  static const int addrsRgbBacklight = 0xE2;

  // Body indices (report id stripped).
  static const int _opOff = 0;
  static const int _addrsOff = 3;
  static const int _lenOff = 4;
  static const int _dataOff = 5;

  /// Config CRC covers this many bytes from data offset (includes zero pad).
  static const int configCrcPayloadLength =
      24; //no opcode/addrs/len//no crc - pure data
  /// Stripped body: header(5) + payload slot(24) + CRC(2).
  static const int configBodyLength = _dataOff + configCrcPayloadLength + 2;

  /// Desktop raw may be report-id + body.
  static const int configRawMaxLength = 1 + configBodyLength;

  // Payload offsets (report id stripped). hid_tool keeps the report id on
  // desktop and drops it on web (WebHID oninputreport has no report id prefix).
  static const int _ackOpcodeOffset = 0;
  static const int _ackDeviceTypeOffset = 5;
  static const int _ackDeviceIdOffset = 6;
  // why: A1 ack payload is len 5: [deviceType][idLo][idHi][0][0]. The device
  // id is 2 bytes (idLo + idHi), already in catalog order on the wire (the
  // mock doc's "AA02" is the customer's display; the device sends 02AA).
  static const int _deviceIdLength = 2;

  // A4 battery ack offsets (report id stripped).
  static const int _batteryPercentOffset = 5; // 0..100
  static const int _batteryChargingOffset = 6; // 0x01 charging, 0x00 not

  // A8 firmware ack offsets (report id stripped). len=8: 2 mouse + 2 dongle.
  // Layout: [0]A8 [1..3]0 [4]8 [5]MS Lo [6]MS Hi [7]Dongle Lo [8]Dongle Hi.
  static const int _firmwareMouseOffset = 5;
  static const int _firmwareDongleOffset = 7;
  static const int _firmwareVersionLength = 2;

  static const Duration _sendTimeout = Duration(milliseconds: 1000);

  @override
  Future<DeviceHandshake> handshake(
    ProtocolTransport session, {
    required int deviceType,
    required String deviceId,
  }) async {
    final ask = _buildAskFrame(deviceType: deviceType, deviceId: deviceId);
    debugPrint('[proto] handshake: sending ask ${_hex(ask)}');
    final ack = await session.sendAndWait(
      data: ask,
      reportId: _reportId,
      reportLength: _frameLength,
      match: (raw) => matchesOpcode(raw, _ackOpcode),
      timeout: _sendTimeout,
    );
    debugPrint('[proto] handshake: received ack ${_hex(ack)} (${ack.length}B)');
    final result = _parseAck(ack);
    debugPrint(
      '[proto] handshake: deviceType=${result.deviceType} '
      'deviceId="${result.deviceId}"',
    );
    return result;
  }

  /// Builds the A1 handshake ask with the expected device type + id.
  ///
  /// why: the firmware echoes the sent type/id back; an all-zero probe makes
  /// it reply all zeros (no match). Offsets after report-id strip:
  /// `[A1][0][0][0][len][deviceType][idLo][idHi]` — type at 5, id at 6-7.
  Uint8List _buildAskFrame({
    required int deviceType,
    required String deviceId,
  }) {
    final frame = Uint8List(_frameLength);
    frame[0] = _askOpcode;
    frame[5] = deviceType;
    // deviceId is a 4-hex-char catalog form (e.g. "02AA"): byte 0 = 0x02,
    // byte 1 = 0xAA, sent in that order per "the id, 02 AA".
    if (deviceId.length == 4) {
      frame[6] = int.parse(deviceId.substring(0, 2), radix: 16);
      frame[7] = int.parse(deviceId.substring(2, 4), radix: 16);
    }
    return frame;
  }

  DeviceHandshake _parseAck(Uint8List raw) {
    final ack = _stripReportId(raw);
    if (ack.length < _ackDeviceIdOffset + _deviceIdLength) {
      throw FormatException('Handshake ack too short: ${ack.length} bytes');
    }
    final opcode = ack[_ackOpcodeOffset];
    if (opcode != _ackOpcode) {
      throw FormatException(
        'Unexpected handshake ack opcode: 0x${opcode.toRadixString(16)}',
      );
    }
    final idBytes = ack.sublist(
      _ackDeviceIdOffset,
      _ackDeviceIdOffset + _deviceIdLength,
    );
    return DeviceHandshake(
      deviceType: DeviceType.fromCode(ack[_ackDeviceTypeOffset]),
      deviceId: idBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );
  }

  @override
  Future<BatteryResult> queryBattery(ProtocolTransport session) async {
    final ask = _buildBatteryFrame();
    debugPrint('[proto] battery: sending ask ${_hex(ask)}');
    final ack = await session.sendAndWait(
      data: ask,
      reportId: _reportId,
      reportLength: _frameLength,
      match: (raw) => matchesOpcode(raw, _batteryOpcode),
      timeout: _sendTimeout,
    );
    debugPrint('[proto] battery: received ack ${_hex(ack)} (${ack.length}B)');
    return _parseBattery(ack);
  }

  Uint8List _buildBatteryFrame() {
    final frame = Uint8List(_frameLength); // 32 bytes, all 00
    frame[0] = _batteryOpcode; // A4, report id 7, rest 00 — no CRC
    return frame;
  }

  BatteryResult _parseBattery(Uint8List raw) {
    final ack = _stripReportId(raw);
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
  Future<FirmwareResult> queryFirmware(ProtocolTransport session) async {
    final ask = _buildFirmwareFrame();
    debugPrint('[proto] firmware: sending ask ${_hex(ask)}');
    final ack = await session.sendAndWait(
      data: ask,
      reportId: _reportId,
      reportLength: _frameLength,
      match: (raw) => matchesOpcode(raw, _firmwareOpcode),
      timeout: _sendTimeout,
    );
    debugPrint('[proto] firmware: received ack ${_hex(ack)} (${ack.length}B)');
    return _parseFirmware(ack);
  }

  Uint8List _buildFirmwareFrame() {
    final frame = Uint8List(_frameLength); // 32 bytes, all 00
    frame[0] = _firmwareOpcode; // A8, report id 7, rest 00 — no CRC
    return frame;
  }

  FirmwareResult _parseFirmware(Uint8List raw) {
    final ack = _stripReportId(raw);
    if (ack.isEmpty) {
      throw FormatException('Firmware ack empty');
    }
    final opcode = ack[0];
    if (opcode != _firmwareOpcode) {
      throw FormatException(
        'Unexpected firmware ack opcode: 0x${opcode.toRadixString(16)}',
      );
    }
    final end = _firmwareDongleOffset + _firmwareVersionLength; // 7+2=9
    if (ack.length < end) {
      throw FormatException('Firmware ack too short: ${ack.length} bytes');
    }
    final mouse = ack.sublist(
      _firmwareMouseOffset,
      _firmwareMouseOffset + _firmwareVersionLength,
    );
    final dongle = ack.sublist(
      _firmwareDongleOffset,
      _firmwareDongleOffset + _firmwareVersionLength,
    );
    return FirmwareResult(mouseVersion: mouse, dongleVersion: dongle);
  }

  // --- Onboard config GET (0x07) / ack (0x08) + addrs -------------------

  @override
  Future<ButtonMappingResult> queryButtonMapping(
    ProtocolTransport session,
  ) async {
    final raw = await _getConfig(session, addrsButtonMapping, 'buttonMapping');
    final data = _configData(raw, addrsButtonMapping);
    final buttons = <ButtonMappingEntry>[];
    for (var i = 0; i + 3 < data.length && buttons.length < 6; i += 4) {
      buttons.add(
        ButtonMappingEntry(
          action: data[i],
          param1: data[i + 1],
          param2: data[i + 2],
          param3: data[i + 3],
        ),
      );
    }
    return ButtonMappingResult(
      buttons: buttonMappingWireToUi(buttons),
      raw: raw,
    );
  }

  @override
  Future<void> setButtonMapping(
    ProtocolTransport session,
    List<ButtonMappingEntry> buttons,
  ) async {
    const label = 'buttonMapping';
    final ask = buildButtonMappingSetFrame(buttons);
    debugPrint(
      '[proto] $label: SET addrs=0x${addrsButtonMapping.toRadixString(16)} '
      'ask ${_hex(ask)}',
    );
    final ack = await session.sendAndWait(
      data: ask,
      reportId: _reportId,
      reportLength: _frameLength,
      match: (raw) => matchesConfigAck(raw, addrs: addrsButtonMapping),
      timeout: _sendTimeout,
    );
    debugPrint('[proto] $label: SET ack ${_hex(ack)} (${ack.length}B)');
    validateConfigAckFrame(ack, addrs: addrsButtonMapping, label: label);
    final body = stripReportId(ack);
    final op = body.isEmpty ? -1 : body[_opOff];
    if (op == _getOpcode || op == _setOpcode) {
      verifyConfigAckCrc(ack, label: label);
    } else {
      debugPrint(
        '[proto] $label: SET ack opcode 0x${op.toRadixString(16)} '
        'not 07/08, skip CRC',
      );
    }
    if (op == _nakOpcode) {
      final reason = body.length > _dataOff ? body[_dataOff] : -1;
      final meaning = const TranslationCodec().nakReasonToLabel(reason);
      throw FormatException(
        '$label SET NAK: $meaning '
        '(reason=0x${(reason & 0xFF).toRadixString(16).padLeft(2, '0')})',
      );
    }
  }

  /// Build SET body for B2 (no report id). Exactly 6 entries → 24 data + CRC.
  ///
  /// L5 encoding loop: map logical UI entries → wire frame + checksum.
  static Uint8List buildButtonMappingSetFrame(
    List<ButtonMappingEntry> buttons,
  ) {
    if (buttons.length != 6) {
      throw ArgumentError.value(
        buttons.length,
        'buttons.length',
        'button mapping SET requires exactly 6 slots',
      );
    }
    final wireButtons = buttonMappingUiToWire(buttons);
    final frame = Uint8List(_frameLength);
    frame[_opOff] = _setOpcode;
    frame[_addrsOff] = addrsButtonMapping;
    frame[_lenOff] = configCrcPayloadLength;
    var o = _dataOff;
    for (final b in wireButtons) {
      frame[o++] = b.action & 0xFF;
      frame[o++] = b.param1 & 0xFF;
      frame[o++] = b.param2 & 0xFF;
      frame[o++] = b.param3 & 0xFF;
    }
    final payload = frame.sublist(_dataOff, _dataOff + configCrcPayloadLength);
    final crc = const Crc16().bytes(payload);
    frame[_dataOff + configCrcPayloadLength] = crc[0];
    frame[_dataOff + configCrcPayloadLength + 1] = crc[1];
    return frame;
  }

  @override
  Future<ReportRateDpiInfoResult> queryReportRateDpiInfo(
    ProtocolTransport session,
  ) async {
    final raw = await _getConfig(session, addrsReportRateDpi, 'reportRateDpi');
    final data = _configData(raw, addrsReportRateDpi);
    if (data.length < 3) {
      throw FormatException('ReportRateDpi data too short: ${data.length}');
    }
    return ReportRateDpiInfoResult(
      reportRate: data[0],
      dpiCurrentLevel: data[1],
      dpiActiveLevel: data[2],
      raw: raw,
    );
  }

  @override
  Future<void> setReportRate(
    ProtocolTransport session,
    Uint8List dataBlock,
  ) async {
    const label = 'reportRate';
    final ask = buildReportRateSetFrame(dataBlock);

    // Log SET frame: data bytes + CRC
    final setData = ask.sublist(_dataOff, _dataOff + 3);
    final setCrc = ask.sublist(_dataOff + 3, _dataOff + 5);
    debugPrint(
      '[proto] $label: SET addrs=0x${addrsReportRateDpi.toRadixString(16)} '
      'data=${_hex(setData)} crc=${_hex(setCrc)}',
    );

    final ack = await session.sendAndWait(
      data: ask,
      reportId: _reportId,
      reportLength: _frameLength,
      match: (raw) => matchesConfigAck(raw, addrs: addrsReportRateDpi),
      timeout: _sendTimeout,
    );
    debugPrint('[proto] $label: SET ack ${_hex(ack)} (${ack.length}B)');
    validateConfigAckFrame(ack, addrs: addrsReportRateDpi, label: label);
    final body = stripReportId(ack);
    final op = body.isEmpty ? -1 : body[_opOff];
    if (op == _getOpcode || op == _setOpcode) {
      // Log ACK: data bytes + CRC from device
      // Data is at _dataOff, CRC is at the last 2 bytes of the body
      final ackData = body.sublist(_dataOff, _dataOff + 3);
      final ackCrc = body.sublist(body.length - 2, body.length);
      debugPrint(
        '[proto] $label: ACK data=${_hex(ackData)} crc=${_hex(ackCrc)}',
      );
      verifyConfigAckCrc(ack, label: label);
    } else {
      debugPrint(
        '[proto] $label: SET ack opcode 0x${op.toRadixString(16)} '
        'not 07/08, skip CRC',
      );
    }
    if (op == _nakOpcode) {
      final reason = body.length > _dataOff ? body[_dataOff] : -1;
      final meaning = const TranslationCodec().nakReasonToLabel(reason);
      throw FormatException(
        '$label SET NAK: $meaning '
        '(reason=0x${(reason & 0xFF).toRadixString(16).padLeft(2, '0')})',
      );
    }
  }

  /// Build SET body for C2 (no report id). 3 bytes data + CRC.
  ///
  /// [dataBlock] must be exactly 3 bytes:
  /// `[reportRateWire, dpiCurrentLevel, dpiActiveLevel]`.
  static Uint8List buildReportRateSetFrame(Uint8List dataBlock) {
    if (dataBlock.length != 3) {
      throw ArgumentError.value(
        dataBlock.length,
        'dataBlock.length',
        'report rate SET requires exactly 3 bytes',
      );
    }
    final frame = Uint8List(_frameLength);
    frame[_opOff] = _setOpcode;
    frame[_addrsOff] = addrsReportRateDpi;
    frame[_lenOff] = 3;
    frame[_dataOff] = dataBlock[0];
    frame[_dataOff + 1] = dataBlock[1];
    frame[_dataOff + 2] = dataBlock[2];
    final payload = frame.sublist(_dataOff, _dataOff + 3);
    final crc = const Crc16().bytes(payload);
    frame[_dataOff + 3] = crc[0];
    frame[_dataOff + 4] = crc[1];
    return frame;
  }

  @override
  Future<DpiTableResult> queryDpiTable(ProtocolTransport session) async {
    final raw = await _getConfig(session, addrsDpiTable, 'dpiTable');
    final data = _configData(raw, addrsDpiTable);
    // Interleaved stage pairs; display DPI is applied via the device sensor profile.
    final stages = <DpiTableEntry>[];
    for (var i = 0; i + 1 < data.length && stages.length < 8; i += 2) {
      stages.add(DpiTableEntry(x: data[i], y: data[i + 1]));
    }
    return DpiTableResult(stages: stages, data: data, raw: raw);
  }

  @override
  Future<void> setDpiTable(
    ProtocolTransport session,
    Uint8List dataBlock,
  ) async {
    const label = 'dpiTable';
    if (dataBlock.length != 16) {
      throw ArgumentError.value(
        dataBlock.length,
        'dataBlock.length',
        'DPI table SET requires exactly 16 bytes',
      );
    }
    final frame = Uint8List(_frameLength);
    frame[_opOff] = _setOpcode;
    frame[_addrsOff] = addrsDpiTable;
    frame[_lenOff] = 16;
    for (var i = 0; i < 16; i++) {
      frame[_dataOff + i] = dataBlock[i];
    }
    final payload = frame.sublist(_dataOff, _dataOff + 16);
    final crc = const Crc16().bytes(payload);
    frame[_dataOff + 16] = crc[0];
    frame[_dataOff + 17] = crc[1];

    debugPrint(
      '[proto] $label: SET addrs=0x${addrsDpiTable.toRadixString(16)} '
      'data=${_hex(payload)} crc=${_hex(crc)}',
    );

    final ack = await session.sendAndWait(
      data: frame,
      reportId: _reportId,
      reportLength: _frameLength,
      match: (raw) => matchesConfigAck(raw, addrs: addrsDpiTable),
      timeout: _sendTimeout,
    );

    validateConfigAckFrame(ack, addrs: addrsDpiTable, label: label);
    verifyConfigAckCrc(ack, label: label);
    debugPrint('[proto] $label: SET ack ${_hex(ack)} (${ack.length}B)');
  }

  @override
  Future<DpiRgbResult> queryDpiRgb(ProtocolTransport session) async {
    final raw = await _getConfig(session, addrsDpiRgb, 'dpiRgb');
    final data = _configData(raw, addrsDpiRgb);
    final stages = <DpiRgbEntry>[];
    for (var i = 0; i + 2 < data.length && stages.length < 8; i += 3) {
      stages.add(DpiRgbEntry(r: data[i], g: data[i + 1], b: data[i + 2]));
    }
    return DpiRgbResult(stages: stages, raw: raw);
  }

  @override
  Future<void> setDpiRgb(ProtocolTransport session, Uint8List dataBlock) async {
    const label = 'dpiRgb';
    if (dataBlock.length != 24) {
      throw ArgumentError.value(
        dataBlock.length,
        'dataBlock.length',
        'DPI RGB SET requires exactly 24 bytes (8 stages x R,G,B)',
      );
    }
    final frame = Uint8List(_frameLength);
    frame[_opOff] = _setOpcode;
    frame[_addrsOff] = addrsDpiRgb;
    frame[_lenOff] = 24;
    for (var i = 0; i < 24; i++) {
      frame[_dataOff + i] = dataBlock[i];
    }
    final payload = frame.sublist(_dataOff, _dataOff + 24);
    final crc = const Crc16().bytes(payload);
    frame[_dataOff + 24] = crc[0];
    frame[_dataOff + 25] = crc[1];

    debugPrint(
      '[proto] $label: SET addrs=0x${addrsDpiRgb.toRadixString(16)} '
      'data=${_hex(payload)} crc=${_hex(crc)}',
    );

    final ack = await session.sendAndWait(
      data: frame,
      reportId: _reportId,
      reportLength: _frameLength,
      match: (raw) => matchesConfigAck(raw, addrs: addrsDpiRgb),
      timeout: _sendTimeout,
    );

    validateConfigAckFrame(ack, addrs: addrsDpiRgb, label: label);
    verifyConfigAckCrc(ack, label: label);
    debugPrint('[proto] $label: SET ack ${_hex(ack)} (${ack.length}B)');
  }

  @override
  Future<SensorOtherResult> querySensorOther(ProtocolTransport session) async {
    final raw = await _getConfig(session, addrsSensorOther, 'sensorOther');
    final data = _configData(raw, addrsSensorOther);
    if (data.length < 18) {
      throw FormatException('SensorOther data too short: ${data.length}');
    }
    return SensorOtherResult(
      // 18-byte layout per TelinkB80 data reference (sheet row after len 18):
      // [ripple(0)][res(1)][angleSnap(2)][res(3)][lod(4)][res(5)][angleTune(6)]
      // [angleValue(7)][res(8)][perf(9)][res(10..12)][debounce(13)][res(14)]
      // [sleep(15)][res(16)][wheel(17)].
      rippleControl: data[0],
      angleSnap: data[2],
      lod: data[4],
      angleTune: data[6],
      angleValue: data[7],
      performance: data[9],
      debounceTime: data[13],
      sleepTime: data[15],
      wheelDirection: data[17],
      data: Uint8List.sublistView(data, 0, 18),
      raw: raw,
    );
  }

  @override
  Future<void> setSensorOther(
    ProtocolTransport session,
    Uint8List dataBlock,
  ) async {
    const label = 'sensorOther';
    if (dataBlock.length != 18) {
      throw ArgumentError.value(
        dataBlock.length,
        'dataBlock.length',
        'sensor/other SET requires exactly 18 bytes',
      );
    }
    final frame = Uint8List(_frameLength);
    frame[_opOff] = _setOpcode;
    frame[_addrsOff] = addrsSensorOther;
    frame[_lenOff] = 18;
    for (var i = 0; i < 18; i++) {
      frame[_dataOff + i] = dataBlock[i];
    }
    final payload = frame.sublist(_dataOff, _dataOff + 18);
    final crc = const Crc16().bytes(payload);
    frame[_dataOff + 18] = crc[0];
    frame[_dataOff + 19] = crc[1];

    debugPrint(
      '[proto] $label: SET addrs=0x${addrsSensorOther.toRadixString(16)} '
      'data=${_hex(payload)} crc=${_hex(crc)}',
    );

    final ack = await session.sendAndWait(
      data: frame,
      reportId: _reportId,
      reportLength: _frameLength,
      match: (raw) => matchesConfigAck(raw, addrs: addrsSensorOther),
      timeout: _sendTimeout,
    );
    debugPrint('[proto] $label: SET ack ${_hex(ack)} (${ack.length}B)');
    validateConfigAckFrame(ack, addrs: addrsSensorOther, label: label);
    final body = stripReportId(ack);
    final op = body.isEmpty ? -1 : body[_opOff];
    if (op == _getOpcode || op == _setOpcode) {
      final ackData = body.sublist(_dataOff, _dataOff + 14);
      final ackCrc = body.sublist(body.length - 2, body.length);
      debugPrint(
        '[proto] $label: ACK data=${_hex(ackData)} crc=${_hex(ackCrc)}',
      );
      verifyConfigAckCrc(ack, label: label);
    } else {
      debugPrint(
        '[proto] $label: SET ack opcode 0x${op.toRadixString(16)} '
        'not 07/08, skip CRC',
      );
    }
    if (op == _nakOpcode) {
      final reason = body.length > _dataOff ? body[_dataOff] : -1;
      final meaning = const TranslationCodec().nakReasonToLabel(reason);
      throw FormatException(
        '$label SET NAK: $meaning '
        '(reason=0x${(reason & 0xFF).toRadixString(16).padLeft(2, '0')})',
      );
    }
  }

  @override
  Future<RgbBacklightResult> queryRgbBacklight(
    ProtocolTransport session,
  ) async {
    final raw = await _getConfig(session, addrsRgbBacklight, 'rgbBacklight');
    final data = _configData(raw, addrsRgbBacklight);
    if (data.length < 8) {
      throw FormatException('RgbBacklight data too short: ${data.length}');
    }
    return RgbBacklightResult(
      enable: data[0],
      mode: data[1],
      brightness: data[2],
      speed: data[3],
      r: data[4],
      g: data[5],
      b: data[6],
      sleepTime: data[7],
      data: Uint8List.fromList(data),
      raw: raw,
    );
  }

  /// Pure 0xE2 SET frame builder (no session) — extracted for unit tests.
  ///
  /// 32-byte body: `[0x08][0][0][0xE2][8][8 data bytes][zeros…][CRC lo][CRC hi]`.
  /// CRC16-Modbus over the 8 data bytes (offsets 5..12), stored at 13..14.
  static Uint8List buildRgbBacklightSetFrame(Uint8List dataBlock) {
    if (dataBlock.length != 8) {
      throw ArgumentError.value(
        dataBlock.length,
        'dataBlock.length',
        'RGB backlight SET requires exactly 8 bytes',
      );
    }
    final frame = Uint8List(_frameLength);
    frame[_opOff] = _setOpcode;
    frame[_addrsOff] = addrsRgbBacklight;
    frame[_lenOff] = 8;
    for (var i = 0; i < 8; i++) {
      frame[_dataOff + i] = dataBlock[i];
    }
    final payload = frame.sublist(_dataOff, _dataOff + 8);
    final crc = const Crc16().bytes(payload);
    frame[_dataOff + 8] = crc[0];
    frame[_dataOff + 9] = crc[1];
    return frame;
  }

  @override
  Future<void> setRgbBacklight(
    ProtocolTransport session,
    Uint8List dataBlock,
  ) async {
    const label = 'rgbBacklight';
    final frame = buildRgbBacklightSetFrame(dataBlock);
    final payload = frame.sublist(_dataOff, _dataOff + 8);

    debugPrint(
      '[proto] $label: SET addrs=0x${addrsRgbBacklight.toRadixString(16)} '
      'data=${_hex(payload)} crc=${_hex(frame.sublist(_dataOff + 8, _dataOff + 10))}',
    );

    final ack = await session.sendAndWait(
      data: frame,
      reportId: _reportId,
      reportLength: _frameLength,
      match: (raw) => matchesConfigAck(raw, addrs: addrsRgbBacklight),
      timeout: _sendTimeout,
    );
    debugPrint('[proto] $label: SET ack ${_hex(ack)} (${ack.length}B)');
    validateConfigAckFrame(ack, addrs: addrsRgbBacklight, label: label);
    final body = stripReportId(ack);
    final op = body.isEmpty ? -1 : body[_opOff];
    if (op == _getOpcode || op == _setOpcode) {
      final ackData = body.sublist(_dataOff, _dataOff + 8);
      final ackCrc = body.sublist(body.length - 2, body.length);
      debugPrint(
        '[proto] $label: ACK data=${_hex(ackData)} crc=${_hex(ackCrc)}',
      );
      verifyConfigAckCrc(ack, label: label);
    } else {
      debugPrint(
        '[proto] $label: SET ack opcode 0x${op.toRadixString(16)} '
        'not 07/08, skip CRC',
      );
    }
    if (op == _nakOpcode) {
      final reason = body.length > _dataOff ? body[_dataOff] : -1;
      final meaning = const TranslationCodec().nakReasonToLabel(reason);
      throw FormatException(
        '$label SET NAK: $meaning '
        '(reason=0x${(reason & 0xFF).toRadixString(16).padLeft(2, '0')})',
      );
    }
  }

  @override
  Future<void> setMacro(
    ProtocolTransport session,
    MacroTransferDefinition macro,
  ) async {
    final chunks = MacroTransferCodec.chunkTransfer(macro);
    for (var chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
      final frame = MacroTransferCodec.buildChunkFrame(
        macroIndex: macro.slot,
        chunkIndex: chunkIndex,
        payload: chunks[chunkIndex],
      );
      debugPrint(
        '[proto] macro: SET slot=${macro.slot} chunk=$chunkIndex '
        'data=${_hex(chunks[chunkIndex])}',
      );
      final reply = await session.sendAndWait(
        data: frame,
        reportId: MacroTransferCodec.reportId,
        reportLength: MacroTransferCodec.frameLength,
        match: (raw) => _matchesMacroReply(raw, macro.slot, chunkIndex),
        timeout: _sendTimeout,
      );
      final body = _stripMacroReportId(reply);
      final status = MacroTransferCodec.parseReplyStatus(body);
      debugPrint(
        '[proto] macro: reply slot=${macro.slot} chunk=$chunkIndex '
        'status=0x${status.toRadixString(16)}',
      );
      if ((chunkIndex < 2 && status != MacroTransferCodec.statusReceived) ||
          (chunkIndex == 2 && status != MacroTransferCodec.statusOk)) {
        throw FormatException(
          'Macro SET rejected: slot=${macro.slot} chunk=$chunkIndex '
          'status=0x${status.toRadixString(16)}',
        );
      }
    }
  }

  static bool _matchesMacroReply(
    Uint8List raw,
    int macroIndex,
    int chunkIndex,
  ) {
    final body = _stripMacroReportId(raw);
    if (body.length <= 5 || body[0] != MacroTransferCodec.opcode) return false;
    return body[1] == chunkIndex &&
        body[3] == macroIndex &&
        body[5] >= MacroTransferCodec.statusReceived;
  }

  static Uint8List _stripMacroReportId(Uint8List raw) {
    if (raw.length >= 2 &&
        raw[0] == MacroTransferCodec.reportId &&
        raw[1] == MacroTransferCodec.opcode) {
      return Uint8List.fromList(raw.sublist(1));
    }
    return raw;
  }

  /// GET ask: opcode 0x07, addrs set, len 0 (sheet: request only needs addrs).
  Uint8List _buildGetFrame(int addrs) {
    final frame = Uint8List(_frameLength);
    frame[_opOff] = _getOpcode;
    frame[_addrsOff] = addrs;
    frame[_lenOff] = 0;
    return frame;
  }

  Future<Uint8List> _getConfig(
    ProtocolTransport session,
    int addrs,
    String label,
  ) async {
    final ask = _buildGetFrame(addrs);
    debugPrint(
      '[proto] $label: GET addrs=0x${addrs.toRadixString(16)} '
      'ask ${_hex(ask)}',
    );
    final ack = await session.sendAndWait(
      data: ask,
      reportId: _reportId,
      reportLength: _frameLength,
      match: (raw) => matchesConfigAck(raw, addrs: addrs),
      timeout: _sendTimeout,
    );
    debugPrint('[proto] $label: ack ${_hex(ack)} (${ack.length}B)');
    // Chart: length → header (addrs) → opcode 07/08? → CRC only if yes → extract.
    validateConfigAckFrame(ack, addrs: addrs, label: label);
    final body = stripReportId(ack);
    final op = body.isEmpty ? -1 : body[_opOff];
    if (op == _getOpcode || op == _setOpcode) {
      verifyConfigAckCrc(ack, label: label);
    } else {
      debugPrint(
        '[proto] $label: opcode 0x${op.toRadixString(16)} '
        'not 07/08, skip CRC',
      );
    }
    if (op == _nakOpcode) {
      // NAK layout: opcode FF, addrs, len, reason in data[0] (sheet).
      final reason = body.length > _dataOff ? body[_dataOff] : -1;
      final meaning = const TranslationCodec().nakReasonToLabel(reason);
      throw FormatException(
        '$label NAK: $meaning '
        '(reason=0x${(reason & 0xFF).toRadixString(16).padLeft(2, '0')})',
      );
    }
    return ack;
  }

  /// Config frame: length + header addrs (B2/C2/C4/…). Opcode 07/08 not required here.
  ///
  /// Throws [CodecException] on failure with raw bytes for logging.
  static void validateConfigAckFrame(
    Uint8List raw, {
    required int addrs,
    String label = 'config',
  }) {
    if (raw.isEmpty || raw.length > configRawMaxLength) {
      debugPrint(
        '[proto] $label: REJECT raw length ${raw.length} (max $configRawMaxLength) raw=${_hex(raw)}',
      );
      throw CodecException(
        label: label,
        reason: 'raw length ${raw.length} (max $configRawMaxLength)',
        raw: raw,
      );
    }
    final body = stripReportId(raw);
    if (body.length < configBodyLength) {
      debugPrint(
        '[proto] $label: REJECT body length ${body.length} (need $configBodyLength) raw=${_hex(raw)}',
      );
      throw CodecException(
        label: label,
        reason: 'body length ${body.length} (need $configBodyLength)',
        raw: raw,
      );
    }
    if (body.length > configBodyLength) {
      debugPrint(
        '[proto] $label: REJECT body length ${body.length} (max $configBodyLength) raw=${_hex(raw)}',
      );
      throw CodecException(
        label: label,
        reason: 'body length ${body.length} (max $configBodyLength)',
        raw: raw,
      );
    }

    // Header: block address (B2, C2, C4, C6, D4, E2, …).
    final gotAddrs = body[_addrsOff];
    if (gotAddrs != addrs) {
      debugPrint(
        '[proto] $label: REJECT addrs=0x${gotAddrs.toRadixString(16)} want=0x${addrs.toRadixString(16)} raw=${_hex(raw)}',
      );
      throw CodecException(
        label: label,
        reason:
            'addrs 0x${gotAddrs.toRadixString(16)} (want 0x${addrs.toRadixString(16)})',
        raw: raw,
      );
    }

    final len = body[_lenOff];
    if (len > configCrcPayloadLength) {
      debugPrint(
        '[proto] $label: REJECT len=$len (max $configCrcPayloadLength) raw=${_hex(raw)}',
      );
      throw CodecException(
        label: label,
        reason: 'len $len (max $configCrcPayloadLength)',
        raw: raw,
      );
    }
  }

  /// CRC-16 over body[5..29), LE at [29..30]. Only for opcode 07/08.
  ///
  /// Throws [CodecException] if CRC does not match with raw bytes for logging.
  static void verifyConfigAckCrc(Uint8List raw, {String label = 'config'}) {
    final body = stripReportId(raw);
    final payloadStart = _dataOff;
    final payloadEnd = _dataOff + configCrcPayloadLength;
    final payload = body.sublist(payloadStart, payloadEnd);
    final wireLo = body[payloadEnd];
    final wireHi = body[payloadEnd + 1];
    final calc = const Crc16().bytes(payload);
    final calcHex =
        '${calc[0].toRadixString(16).padLeft(2, '0')} '
        '${calc[1].toRadixString(16).padLeft(2, '0')}';
    final wireHex =
        '${wireLo.toRadixString(16).padLeft(2, '0')} '
        '${wireHi.toRadixString(16).padLeft(2, '0')}';
    final match = calc[0] == wireLo && calc[1] == wireHi;
    debugPrint(
      '[proto] $label: CRC calc=$calcHex wire=$wireHex '
      'match=$match',
    );
    if (!match) {
      debugPrint(
        '[proto] $label: REJECT CRC mismatch calc=$calcHex wire=$wireHex raw=${_hex(raw)}',
      );
      throw CodecException(
        label: label,
        reason: 'CRC mismatch: calc=$calcHex wire=$wireHex',
        raw: raw,
      );
    }
  }

  /// Data bytes from a config reply; checks opcode + addrs.
  ///
  /// Device may reply with SET (0x08) per sheet, or GET (0x07) with len+data
  /// filled (observed on M7XSE for B2).
  Uint8List _configData(Uint8List raw, int addrs) {
    final body = stripReportId(raw);
    if (body.length <= _lenOff) {
      throw FormatException('Config ack too short: ${body.length}');
    }
    final op = body[_opOff];
    if (op != _setOpcode && op != _getOpcode) {
      throw FormatException(
        'Unexpected config opcode: 0x${op.toRadixString(16)}',
      );
    }
    if (body[_addrsOff] != addrs) {
      throw FormatException(
        'Config addrs mismatch: got 0x${body[_addrsOff].toRadixString(16)} '
        'want 0x${addrs.toRadixString(16)}',
      );
    }
    final len = body[_lenOff];
    final end = _dataOff + len;
    if (body.length < end) {
      throw FormatException(
        'Config data short: need $end have ${body.length} (len=$len)',
      );
    }
    return Uint8List.fromList(body.sublist(_dataOff, end));
  }

  /// Match config reply for [addrs]: GET(0x07) or SET(0x08) with that addrs,
  /// or NAK(0xFF) so caller can surface the reason.
  ///
  /// Hardware (M7XSE) returned GET+data for button mapping, not SET.
  static bool matchesConfigAck(
    Uint8List raw, {
    required int addrs,
    int reportId = _reportId,
  }) {
    final body = stripReportId(raw, reportId: reportId);
    if (body.length <= _addrsOff) return false;
    final op = body[_opOff];
    if (op == _nakOpcode) {
      // Prefer NAK that names our addrs when present.
      return body.length <= _addrsOff || body[_addrsOff] == addrs;
    }
    if (body[_addrsOff] != addrs) return false;
    return op == _setOpcode || op == _getOpcode;
  }

  Uint8List _stripReportId(Uint8List raw) => stripReportId(raw);

  /// Strip desktop report-id prefix only when byte1 is a known opcode.
  ///
  /// GET opcode is also 0x07. On web the body starts with 0x07 0x00 … — do not
  /// treat that as report-id + opcode or matching breaks.
  static Uint8List stripReportId(Uint8List raw, {int reportId = _reportId}) {
    if (raw.length >= 2 && raw[0] == reportId && _isBodyOpcode(raw[1])) {
      return Uint8List.fromList(raw.sublist(1));
    }
    return raw;
  }

  static bool _isBodyOpcode(int b) =>
      b == _askOpcode ||
      b == _batteryOpcode ||
      b == _firmwareOpcode ||
      b == _getOpcode ||
      b == _setOpcode ||
      b == _nakOpcode;

  /// True when payload opcode (after optional report-id byte) equals [opcode].
  static bool matchesOpcode(
    Uint8List raw,
    int opcode, {
    int reportId = _reportId,
  }) {
    final body = stripReportId(raw, reportId: reportId);
    return body.isNotEmpty && body[0] == opcode;
  }

  static String _hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}
