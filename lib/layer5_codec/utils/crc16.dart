import 'dart:typed_data';

/// CRC-16/MODBUS, exact port of the device firmware's `crc16_user()`.
///
/// Parameters: polynomial 0xA001 (reflected 0x8005), initial 0xFFFF, reflected
/// input and output, no final XOR. Use this for every device frame's checksum.
class Crc16 {
  const Crc16();

  /// Computes the CRC-16 of [data].
  int compute(Uint8List data) {
    var crc = 0xFFFF;
    for (final b in data) {
      var ds = b;
      for (var i = 0; i < 8; i++) {
        crc = (crc >> 1) ^ ((crc ^ ds) & 1) * 0xA001;
        ds >>= 1;
      }
    }
    return crc & 0xFFFF;
  }

  /// Computes the CRC-16 of [data] and returns it as two bytes, little-endian
  /// (low byte first). Append these to the frame as the checksum.
  Uint8List bytes(Uint8List data) {
    final crc = compute(data);
    return Uint8List.fromList([crc & 0xFF, (crc >> 8) & 0xFF]);
  }

  /// Verifies [data] (without the trailing 2 CRC bytes) against [expected].
  bool verify(Uint8List data, int expected) => compute(data) == expected;
}
