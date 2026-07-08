import 'package:hid_tool/hid_tool.dart';

import '../hid/hid_scanner.dart';
import '../hid/hid_scanner_factory.dart';
import 'device_catalog.dart';
import 'discovered_device.dart';

/// Catalog-driven device discovery and matching.
///
/// The ONE component that marries raw [HidDevice] handles to supported catalog
/// entries. No feature re-scans or re-matches on its own — it calls
/// [discover] and receives a list of [DiscoveredDevice]s.
///
/// Matching is pure data comparison (vid/pid/usagePage) and therefore shared
/// across platforms. The only platform awareness lives in [HidScanner.current],
/// which this scanner delegates to.
class DeviceScanner {
  final HidScanner _scanner;

  DeviceScanner([HidScanner? scanner])
      : _scanner = scanner ?? HidScannerFactory.current();

  /// Discovers all supported devices currently available to the app.
  ///
  /// Reads the approved catalog, builds a [DeviceFilter] per device×mode,
  /// scans via the platform scanner, then matches each returned [HidDevice]
  /// back to its catalog entry by vid/pid/usagePage.
  ///
  /// On web this may present a browser permission picker; callers should
  /// invoke it from a user gesture (e.g. a button tap).
  Future<List<DiscoveredDevice>> discover() async {
    final entries = await DeviceCatalog.load();

    // Build one filter per device×mode — the catalog is the source of which
    // vid/pid/usagePage combinations we care about.
    final filters = <DeviceFilter>[];
    final byFilter = <_FilterKey, _Match>{};
    for (final entry in entries) {
      for (final mode in entry.modes) {
        final filter = mode.toFilter(entry.usagePage);
        filters.add(filter);
        byFilter[_FilterKey(mode.vid, mode.pid, entry.usagePage)] =
            _Match(entry, mode);
      }
    }

    final devices = await _scanner.scan(filters);

    final discovered = <DiscoveredDevice>[];
    for (final dev in devices) {
      final match = byFilter[_FilterKey(dev.vendorId, dev.productId, dev.usagePage)];
      if (match != null) {
        discovered.add(DiscoveredDevice(
          entry: match.entry,
          mode: match.mode,
          hidDevice: dev,
        ));
      }
    }
    return discovered;
  }
}

class _FilterKey {
  final int vid, pid, usagePage;
  const _FilterKey(this.vid, this.pid, this.usagePage);

  @override
  bool operator ==(Object other) =>
      other is _FilterKey && vid == other.vid && pid == other.pid && usagePage == other.usagePage;

  @override
  int get hashCode => Object.hash(vid, pid, usagePage);
}

class _Match {
  final DeviceCatalogEntry entry;
  final DeviceMode mode;
  const _Match(this.entry, this.mode);
}
