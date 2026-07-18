import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hid_tool/hid_tool.dart';

import 'package:driver_hub/layer2_capabilities/device_type.dart';

/// Catalog entry for one supported device, parsed from the approved
/// `assets/catalog/supported_model.json`.
///
/// Shared device registry (mouse, later keyboard). Mouse capabilities load per
/// model (`assets/catalog/mouse/{model}.json`, e.g. m7xse.json); sensors from
/// `assets/catalog/mouse/sensors.json` (see [DeviceCapabilityStore],
/// [SensorProfiles]).
/// [DeviceScanner] reads this registry to build discovery filters and to match
/// raw [HidDevice]s back to catalog entries.
class DeviceCatalogEntry {
  final String devId;
  final DeviceType deviceType;
  final String model;
  final String deviceAttr;
  final int interfaceId;
  final int usagePage;
  final DeviceImage image;
  final List<DeviceMode> modes;

  const DeviceCatalogEntry({
    required this.devId,
    required this.deviceType,
    required this.model,
    required this.deviceAttr,
    required this.interfaceId,
    required this.usagePage,
    required this.image,
    required this.modes,
  });

  factory DeviceCatalogEntry.fromJson(Map<String, dynamic> json) {
    return DeviceCatalogEntry(
      devId: json['devId'] as String,
      deviceType: DeviceType.fromCatalogCode(json['deviceType'] as int),
      model: json['model'] as String,
      deviceAttr: json['deviceAttr'] as String,
      interfaceId: json['interfaceId'] as int,
      usagePage: _parseHex(json['usagePage']),
      image: DeviceImage.fromJson(json['image'] as Map<String, dynamic>),
      modes: (json['modes'] as List)
          .map((m) => DeviceMode.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Device display images, from the registry.
class DeviceImage {
  final String small;
  final String large;

  const DeviceImage({required this.small, required this.large});

  factory DeviceImage.fromJson(Map<String, dynamic> json) {
    return DeviceImage(
      small: json['small'] as String,
      large: json['large'] as String,
    );
  }
}

/// One connection mode of a device (USB / 2.4G).
class DeviceMode {
  final int mode; // 0=USB, 1=2.4G
  final String desc;
  final int vid;
  final int pid;

  const DeviceMode({
    required this.mode,
    required this.desc,
    required this.vid,
    required this.pid,
  });

  factory DeviceMode.fromJson(Map<String, dynamic> json) {
    return DeviceMode(
      mode: json['mode'] as int,
      desc: json['desc'] as String,
      vid: _parseHex(json['vid']),
      pid: _parseHex(json['pid']),
    );
  }

  /// Builds the discovery filter for this mode.
  DeviceFilter toFilter(int usagePage) => DeviceFilter(
        vendorId: vid,
        productId: pid,
        usagePage: usagePage,
      );
}

/// Loads the device catalog from `assets/catalog/supported_model.json`.
///
/// The catalog is the approved registry; this class is the only reader.
/// Callers obtain the parsed entries via [load].
class DeviceCatalog {
  static const _assetPath = 'assets/catalog/supported_model.json';

  /// Loads all supported device entries. Cached after first load.
  static Future<List<DeviceCatalogEntry>> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final devices = json['devices'] as List;
    return devices
        .map((d) => DeviceCatalogEntry.fromJson(d as Map<String, dynamic>))
        .toList(growable: false);
  }
}

/// Parses a hex value that may be an int or a "0x.."/".." string.
int _parseHex(dynamic value) {
  if (value is int) return value;
  if (value is String) {
    final s = value.toLowerCase().replaceAll('0x', '').trim();
    return int.parse(s, radix: 16);
  }
  throw FormatException('Cannot parse hex value: $value');
}
