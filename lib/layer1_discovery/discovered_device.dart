import 'package:hid_tool/hid_tool.dart';

import 'device_catalog.dart';

/// A device that was discovered on the bus AND matched to a supported catalog
/// entry.
///
/// This is the object everything downstream holds — features, repositories,
/// the UI. It bundles the raw [hidDevice] handle with the catalog context
/// ([entry] + [mode]) so consumers never need to re-match.
class DiscoveredDevice {
  /// The catalog entry this device matched.
  final DeviceCatalogEntry entry;

  /// The connection mode (USB / 2.4G) the device was found on.
  final DeviceMode mode;

  /// The raw HID handle from hid_tool. Open it via [HidSession].
  final HidDevice hidDevice;

  const DiscoveredDevice({
    required this.entry,
    required this.mode,
    required this.hidDevice,
  });

  /// Stable identifier: devId + mode.
  String get id => '${entry.devId}:${mode.mode}';

  @override
  String toString() => 'DiscoveredDevice($id, ${entry.model}, ${mode.desc})';
}
