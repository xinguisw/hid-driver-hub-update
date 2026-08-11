import 'dart:typed_data';

import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:driver_hub/layer5_codec/protocol_transport.dart';
import 'package:driver_hub/layer5_codec/utils/crc16.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all config SET packets put CRC at raw bytes 30-31', () async {
    final protocol = const MouseProtocol();

    final buttonTransport = _CaptureTransport(
      address: MouseProtocol.addrsButtonMapping,
      data: List<int>.generate(24, (i) => i + 1),
    );
    await protocol.setButtonMapping(buttonTransport, [
      for (var i = 0; i < 6; i++)
        ButtonMappingEntry(action: i + 1, param1: 0, param2: 0, param3: 0),
    ]);
    _expectFixedCrc(buttonTransport, length: 24);

    final reportRateTransport = _CaptureTransport(
      address: MouseProtocol.addrsReportRateDpi,
      data: [1, 2, 3],
    );
    await protocol.setReportRate(
      reportRateTransport,
      Uint8List.fromList([1, 2, 3]),
    );
    _expectFixedCrc(reportRateTransport, length: 3);

    final dpiTransport = _CaptureTransport(
      address: MouseProtocol.addrsDpiTable,
      data: List<int>.generate(16, (i) => i + 1),
    );
    await protocol.setDpiTable(
      dpiTransport,
      Uint8List.fromList(List<int>.generate(16, (i) => i + 1)),
    );
    _expectFixedCrc(dpiTransport, length: 16);

    final dpiRgbTransport = _CaptureTransport(
      address: MouseProtocol.addrsDpiRgb,
      data: List<int>.generate(24, (i) => i + 1),
    );
    await protocol.setDpiRgb(
      dpiRgbTransport,
      Uint8List.fromList(List<int>.generate(24, (i) => i + 1)),
    );
    _expectFixedCrc(dpiRgbTransport, length: 24);

    final sensorTransport = _CaptureTransport(
      address: MouseProtocol.addrsSensorOther,
      data: List<int>.generate(18, (i) => i + 1),
    );
    await protocol.setSensorOther(
      sensorTransport,
      Uint8List.fromList(List<int>.generate(18, (i) => i + 1)),
    );
    _expectFixedCrc(sensorTransport, length: 18);

    final backlightTransport = _CaptureTransport(
      address: MouseProtocol.addrsRgbBacklight,
      data: List<int>.generate(8, (i) => i + 1),
    );
    await protocol.setRgbBacklight(
      backlightTransport,
      Uint8List.fromList(List<int>.generate(8, (i) => i + 1)),
    );
    _expectFixedCrc(backlightTransport, length: 8);
  });
}

void _expectFixedCrc(_CaptureTransport capture, {required int length}) {
  final frame = capture.sent!;
  expect(frame.length, 32);
  expect(capture.reportId, 0x07);
  expect(capture.reportLength, 32);
  expect(frame[3], capture.address);
  expect(frame[4], length);

  final paddedPayload = Uint8List(24);
  paddedPayload.setRange(0, length, frame.sublist(5, 5 + length));
  final expected = const Crc16().bytes(paddedPayload);

  // [frame] is the report-id-stripped body.  The HID desktop report puts
  // 0x07 in front of it, so the protocol CRC is at raw bytes 30-31.
  final desktopRaw = Uint8List(frame.length + 1);
  desktopRaw[0] = capture.reportId!;
  desktopRaw.setRange(1, desktopRaw.length, frame);
  expect(desktopRaw.sublist(30, 32), expected);

  // Keep the body-level assertion too: it documents the equivalent offsets
  // after stripReportId() and prevents a test-only coordinate mismatch.
  expect(frame.sublist(29, 31), expected);
  expect(frame.sublist(5 + length, 29), everyElement(0));
}

class _CaptureTransport implements ProtocolTransport {
  _CaptureTransport({required this.address, required this.data});

  final int address;
  final List<int> data;
  Uint8List? sent;
  int? reportId;
  int? reportLength;

  @override
  Future<Uint8List> sendAndWait({
    required Uint8List data,
    required int reportId,
    required int reportLength,
    required bool Function(Uint8List raw) match,
    Duration timeout = const Duration(milliseconds: 1000),
  }) async {
    sent = Uint8List.fromList(data);
    this.reportId = reportId;
    this.reportLength = reportLength;
    final ack = Uint8List(31);
    ack[0] = 0x08;
    ack[3] = address;
    ack[4] = this.data.length;
    ack.setRange(5, 5 + this.data.length, this.data);
    final payload = Uint8List.sublistView(ack, 5, 29);
    final crc = const Crc16().bytes(payload);
    ack[29] = crc[0];
    ack[30] = crc[1];
    return ack;
  }
}
