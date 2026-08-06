import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Sensor DPI-encoding tables and per-device sensor profiles.
///
/// Product data lives in [assets/catalog/mouse/sensors.json].
/// This file holds the typed model and loader only.

/// How a sensor encodes a DPI value onto the wire.
class DpiEncoding {
  /// `identity` | `divide` | `multiply` | `paw3311`.
  final String transform;
  final int factor;
  final int bytesPerAxis;
  final String endian;
  final bool independentXY;

  /// Optional wire-code → display DPI (e.g. PAW3311 SDK table `0x13` → 840).
  final Map<int, int> cpiMap;

  const DpiEncoding({
    required this.transform,
    required this.factor,
    required this.bytesPerAxis,
    required this.endian,
    required this.independentXY,
    this.cpiMap = const {},
  });

  factory DpiEncoding.fromJson(Map<String, dynamic> json) {
    final rawMap = json['cpiMap'];
    final cpiMap = <int, int>{};
    if (rawMap is Map) {
      for (final e in rawMap.entries) {
        final k = _parseWireKey(e.key);
        final v = e.value;
        if (v is int) {
          cpiMap[k] = v;
        } else if (v is num) {
          cpiMap[k] = v.toInt();
        }
      }
    }
    return DpiEncoding(
      transform: json['transform'] as String,
      factor: json['factor'] as int,
      bytesPerAxis: json['bytesPerAxis'] as int,
      endian: json['endian'] as String,
      independentXY: json['independentXY'] as bool,
      cpiMap: cpiMap,
    );
  }

  static int _parseWireKey(Object? key) {
    final s = key.toString().trim();
    if (s.startsWith('0x') || s.startsWith('0X')) {
      return int.parse(s.substring(2), radix: 16);
    }
    return int.parse(s);
  }
}

/// One encoding table, keyed by `<chip>/<mode>`.
class EncodingTable {
  final String chip;
  final String mode;
  final DpiEncoding dpiEncoding;
  const EncodingTable({
    required this.chip,
    required this.mode,
    required this.dpiEncoding,
  });

  factory EncodingTable.fromJson(Map<String, dynamic> json) {
    return EncodingTable(
      chip: json['chip'] as String,
      mode: json['mode'] as String,
      dpiEncoding: DpiEncoding.fromJson(
          json['dpiEncoding'] as Map<String, dynamic>),
    );
  }
}

/// Which encoding table a device+mode uses.
class SensorProfile {
  final String chip;
  final String mode;
  final String table; // key into EncodingTables
  const SensorProfile({
    required this.chip,
    required this.mode,
    required this.table,
  });

  factory SensorProfile.fromJson(Map<String, dynamic> json) {
    return SensorProfile(
      chip: json['chip'] as String,
      mode: json['mode'] as String,
      table: json['table'] as String,
    );
  }
}

/// Loads encoding tables and sensor profiles from
/// [assets/catalog/mouse/sensors.json].
///
/// Not loaded at app start. Load with capabilities when the user opens
/// mouse settings (device card → settings). Cached after first [load].
class SensorProfiles {
  SensorProfiles._();

  static const _assetPath = 'assets/catalog/mouse/sensors.json';

  static Map<String, EncodingTable>? _tables;
  static Map<String, SensorProfile>? _byDevice;

  /// Loads sensor data from the asset JSON. Cached after first load.
  /// Call when entering mouse settings, not at app start.
  static Future<void> load() async {
    if (_tables != null) return;
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final tablesJson = json['tables'] as Map<String, dynamic>;
    final tables = <String, EncodingTable>{};
    for (final e in tablesJson.entries) {
      tables[e.key] =
          EncodingTable.fromJson(e.value as Map<String, dynamic>);
    }

    final devicesJson = json['devices'] as Map<String, dynamic>;
    final byDevice = <String, SensorProfile>{};
    for (final e in devicesJson.entries) {
      byDevice[e.key] =
          SensorProfile.fromJson(e.value as Map<String, dynamic>);
    }

    _tables = tables;
    _byDevice = byDevice;
  }

  /// Test-only: clear cache so asset reloads pick up JSON edits.
  static void debugReset() {
    _tables = null;
    _byDevice = null;
  }

  /// Profile for [devId] only (one sensor per product; USB and 2.4G share it).
  static SensorProfile? forDevice(String devId) => _byDevice?[devId];

  static EncodingTable? table(String key) => _tables?[key];
}
