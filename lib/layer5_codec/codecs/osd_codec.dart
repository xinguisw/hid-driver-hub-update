import 'dart:typed_data';

import '../device_protocol.dart';

/// OSD performance-change payload from report 9, opcode 1.
///
/// M7X PRO captures encode the zero-based DPI stage before the report-rate
/// wire value after the opcode and reserved byte. The wire values stay here;
/// L4 translates them into product meaning before they reach presentation.
class OsdPerformanceResult {
  final int reportRateWire;
  final int dpiLevel;
  final int? dpiValue;

  const OsdPerformanceResult({
    required this.reportRateWire,
    required this.dpiLevel,
    this.dpiValue,
  });

  @override
  String toString() =>
      'OsdPerformanceResult(rate=$reportRateWire, dpiLevel=$dpiLevel, dpiValue=$dpiValue)';
}

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

  /// Parse a report-rate/DPI change push (opcode 1).
  ///
  /// New format: `[report_id] | opcode | report-rate wire | DPI stage wire | DPI High | DPI Low | ...`.
  /// Legacy format: `[report_id] | opcode | reserved (0x00) | DPI stage wire | report-rate wire | ...`.
  OsdPerformanceResult? parsePerformance(Uint8List raw) {
    final body = _extractBody(raw);
    if (body == null || body.length < 4 || body[0] != opcodeDpiRate) return null;

    int reportRateWire;
    int dpiLevel;
    int? dpiValue;

    if (body[1] == 0x00) {
      // Legacy format: [opcode (1), reserved (0), dpiLevel, reportRateWire, ...]
      dpiLevel = body[2];
      reportRateWire = body[3];
    } else {
      // New format: [opcode (1), reportRateWire, dpiLevel, dpiHigh, dpiLow, ...]
      reportRateWire = body[1];
      dpiLevel = body[2];
      if (body.length >= 5) {
        final high = body[3];
        final low = body[4];
        final rawDpi = (high << 8) | low;
        if (rawDpi > 0) {
          dpiValue = rawDpi;
        }
      }
    }

    return OsdPerformanceResult(
      reportRateWire: reportRateWire,
      dpiLevel: dpiLevel,
      dpiValue: dpiValue,
    );
  }

  /// Parse battery push (opcode 2). Null if not a battery OSD frame.
  ///
  /// Captured frame: `[09] 02 00 64 01 00 00 00`
  ///   [0]=opcode 2, [1]=reserved 0, [2]=percent (0x64=100), [3]=charging.
  BatteryResult? parseBattery(Uint8List raw) {
    final body = _extractBody(raw);
    if (body == null || body.length < 4 || body[0] != opcodeBattery) return null;
    // Battery opcode has reserved 0x00 at body[1]
    if (body[1] != 0x00) return null;
    final percentByte = body[2];
    if (percentByte > 100) return null;
    final charging = body[3] != 0;
    return BatteryResult(percent: percentByte, isCharging: charging);
  }

  /// True if [raw] is a recognized OSD frame (desktop or WebHID format).
  bool isOsdFrame(Uint8List raw) => _extractBody(raw) != null;

  /// Unified OSD body extractor for Desktop (report ID 9 or 1) and WebHID (opcode-direct or report-ID prefixed).
  Uint8List? _extractBody(Uint8List raw) {
    if (raw.length < 4) return null;

    // Pattern 1a: Report ID 0x09 prepended before opcode (0x01 or 0x02)
    if (raw[0] == reportId &&
        (raw[1] == opcodeDpiRate || raw[1] == opcodeBattery)) {
      return Uint8List.sublistView(raw, 1);
    }

    // Pattern 1b: Report ID 0x01 prepended before opcode (0x01 or 0x02) AND reserved byte 0x00
    if (raw[0] == 0x01 &&
        (raw[1] == opcodeDpiRate || raw[1] == opcodeBattery) &&
        raw[2] == 0x00) {
      return Uint8List.sublistView(raw, 1);
    }

    // Pattern 2: Opcode directly at byte 0 (0x01 for performance, 0x02 for battery)
    if (raw[0] == opcodeDpiRate || raw[0] == opcodeBattery) {
      return raw;
    }

    return null;
  }
}
