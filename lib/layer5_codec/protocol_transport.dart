import 'dart:typed_data';

/// L5's transport boundary for one request/reply HID exchange.
///
/// The codec knows a framed request, report id, expected length, and reply
/// matcher. L6 supplies the concrete HID queue/session implementation.
abstract interface class ProtocolTransport {
  Future<Uint8List> sendAndWait({
    required Uint8List data,
    required int reportId,
    required int reportLength,
    required bool Function(Uint8List raw) match,
    Duration timeout = const Duration(seconds: 3),
  });
}
