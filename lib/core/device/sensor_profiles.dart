/// Sensor DPI-encoding tables and per-device sensor profiles.
//
// Defined in Dart, not in a JSON data file. Transcribed from the former
// `assets/catalog/mouse/profile/sensors.json`. Adding a device's sensor
// profile means adding a Dart entry, not editing a data file.
library;

/// How a sensor encodes a DPI value onto the wire.
class DpiEncoding {
  /// 'divide' (wire = value / factor) or 'multiply'.
  final String transform;
  final int factor;
  final int bytesPerAxis;
  final String endian;
  final bool independentXY;

  const DpiEncoding({
    required this.transform,
    required this.factor,
    required this.bytesPerAxis,
    required this.endian,
    required this.independentXY,
  });
}

/// The DPI range a sensor supports.
class DpiRange {
  final int minDpi;
  final int maxDpi;
  final int step;
  const DpiRange({required this.minDpi, required this.maxDpi, required this.step});
}

/// One encoding table, keyed by `<chip>/<mode>`.
class EncodingTable {
  final String chip;
  final String mode;
  final DpiEncoding dpiEncoding;
  final DpiRange dpiRange;
  const EncodingTable({
    required this.chip,
    required this.mode,
    required this.dpiEncoding,
    required this.dpiRange,
  });
}

/// Which encoding table a device+mode uses.
class SensorProfile {
  final String chip;
  final String mode;
  final String table; // key into EncodingTables
  const SensorProfile({required this.chip, required this.mode, required this.table});
}

/// Hardcoded encoding tables and sensor profiles.
///
/// No JSON read. Adding a sensor means adding Dart entries here.
class SensorProfiles {
  const SensorProfiles._();

  static SensorProfile? forDevice(String devId, int mode) =>
      _byDevice['$devId:$mode'];

  static EncodingTable? table(String key) => _tables[key];

  static const _tables = <String, EncodingTable>{
    'PAW3395/high_res': EncodingTable(
      chip: 'PAW3395',
      mode: 'high_res',
      dpiEncoding: DpiEncoding(
        transform: 'divide',
        factor: 50,
        bytesPerAxis: 1,
        endian: 'big',
        independentXY: true,
      ),
      dpiRange: DpiRange(minDpi: 100, maxDpi: 26000, step: 50),
    ),
    'PAW3395/std_res': EncodingTable(
      chip: 'PAW3395',
      mode: 'std_res',
      dpiEncoding: DpiEncoding(
        transform: 'divide',
        factor: 25,
        bytesPerAxis: 1,
        endian: 'big',
        independentXY: true,
      ),
      dpiRange: DpiRange(minDpi: 100, maxDpi: 16000, step: 50),
    ),
  };

  static const _byDevice = <String, SensorProfile>{
    'm7xse:1': SensorProfile(chip: 'PAW3395', mode: 'high_res', table: 'PAW3395/high_res'),
  };
}
