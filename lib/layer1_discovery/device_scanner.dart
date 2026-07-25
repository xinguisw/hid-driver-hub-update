import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hid_tool/hid_tool.dart';

import 'package:driver_hub/layer6_transport/hid_scanner.dart';
import 'package:driver_hub/layer6_transport/hid_scanner_factory.dart';
import 'device_catalog.dart';
import 'discovered_device.dart';

/// Catalog-driven device discovery and matching.
///
/// The ONE component that marries raw [HidDevice] handles to supported catalog
/// entries. No feature re-scans or re-matches on its own — it calls
/// [discover] / [discoverAuthorized] and receives a list of [DiscoveredDevice]s.
///
/// Match rules from [supported_model.json]:
/// - always: (vid, pid) against catalog modes
/// - desktop: [HidDevice.interfaceNumber] == entry.interfaceId
/// - web: VID/PID only here; catalog usagePage filter is L6 [WebHidScanner]
class DeviceScanner {
  final HidScanner _scanner;

  DeviceScanner([HidScanner? scanner])
      : _scanner = scanner ?? HidScannerFactory.current();

  /// Discovers supported devices. Uses the gesture path: on web this may
  /// present a browser permission picker. Invoke from a user gesture.
  Future<List<DiscoveredDevice>> discover() => _discover(useAuthorized: false);

  /// Discovers supported devices without a user gesture. On web returns only
  /// previously-granted devices (no picker). Used by the reconnect watcher.
  Future<List<DiscoveredDevice>> discoverAuthorized() =>
      _discover(useAuthorized: true);

  Future<List<DiscoveredDevice>> _discover({required bool useAuthorized}) async {
    final entries = await DeviceCatalog.load();

    final filters = <DeviceFilter>[];
    final byVidPid = <_VidPidKey, _Match>{};
    for (final entry in entries) {
      for (final mode in entry.modes) {
        filters.add(mode.toFilter(entry.usagePage));
        byVidPid[_VidPidKey(mode.vid, mode.pid)] = _Match(entry, mode);
      }
    }

    final devices = useAuthorized
        ? await _scanner.getAuthorized(filters)
        : await _scanner.scan(filters);

    final discovered = <DiscoveredDevice>[];
    for (final dev in devices) {
      final match = byVidPid[_VidPidKey(dev.vendorId, dev.productId)];
      if (match == null) continue;
      if (!_matchesDesktopInterface(dev, match.entry)) continue;
      discovered.add(DiscoveredDevice(
        entry: match.entry,
        mode: match.mode,
        hidDevice: dev,
      ));
    }
    return discovered;
  }

  /// Desktop only: catalog [DeviceCatalogEntry.interfaceId].
  /// Web: always true (usagePage is L6).
  bool _matchesDesktopInterface(
    HidDevice device,
    DeviceCatalogEntry entry,
  ) {
    if (kIsWeb) return true;
    return device.interfaceNumber == entry.interfaceId;
  }
}

class _VidPidKey {
  final int vid, pid;
  const _VidPidKey(this.vid, this.pid);

  @override
  bool operator ==(Object other) =>
      other is _VidPidKey && vid == other.vid && pid == other.pid;

  @override
  int get hashCode => Object.hash(vid, pid);
}

class _Match {
  final DeviceCatalogEntry entry;
  final DeviceMode mode;
  const _Match(this.entry, this.mode);
}
