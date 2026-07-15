import 'dart:typed_data';

import '../device_protocol.dart';

/// Telink OSD (usage 0xFF02, report id 9, 8 bytes).
///
/// Sheet layout: reportId | opcode | data[0]…data[5]
/// Desktop: first byte is usually 0x09.
/// Web: report id may be omitted; only accept short frames with opcode 2 and
/// percent in range (avoids treating boot-mouse button bytes as OSD).
class OsdCodec {
  const OsdCodec();

  static const int reportId = 0x09;
  static const int opcodeDpiRate = 0x01;
  static const int opcodeBattery = 0x02;

  /// Parse battery push (opcode 2). Null if not a battery OSD frame.
  ///
  /// Captured desktop frame: `09 02 00 64 01 00 00 00`
  /// after strip report id:   `   02 00 64 01 00 00 00`
  ///   [0]=opcode 2, [1]=reserved 0, [2]=percent (0x64=100), [3]=charging.
  BatteryResult? parseBattery(Uint8List raw) {
    if (!_looksLikeOsd(raw)) return null;
    final body = _body(raw);
    if (body.isEmpty || body[0] != opcodeBattery) return null;
    if (body.length < 4) return null;
    final percentByte = body[2];
    // A4 uses 0..100; reject garbage that is not a plausible battery byte.
    if (percentByte > 100) return null;
    final charging = body[3] != 0;
    return BatteryResult(percent: percentByte, isCharging: charging);
  }

  /// True if [raw] is report-id 9, or a short web-style OSD body.
  bool isOsdFrame(Uint8List raw) => _looksLikeOsd(raw);

  bool _looksLikeOsd(Uint8List raw) {
    if (raw.isEmpty) return false;
    // Desktop (and any path that prefixes report id).
    if (raw[0] == reportId && raw.length >= 3) return true;
    // Web: no report-id prefix. Only 8-byte frames starting with known OSD
    // opcodes — never treat random 0x01/0x02 button reports of other sizes.
    if (raw.length == 8 &&
        (raw[0] == opcodeDpiRate || raw[0] == opcodeBattery)) {
      return true;
    }
    return false;
  }

  Uint8List _body(Uint8List raw) {
    if (raw.isNotEmpty && raw[0] == reportId) {
      return Uint8List.fromList(raw.sublist(1));
    }
    return raw;
  }
}
