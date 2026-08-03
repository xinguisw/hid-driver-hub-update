import 'dart:typed_data';

/// L5 protocol decode failure.
///
/// Thrown when a raw frame fails validation (header, opcode, CRC).
/// Carries the raw bytes so callers can log the corruption footprint.
class CodecException implements Exception {
  final String label;
  final String reason;
  final Uint8List? raw;

  const CodecException({
    required this.label,
    required this.reason,
    this.raw,
  });

  @override
  String toString() => 'CodecException($label): $reason';
}
