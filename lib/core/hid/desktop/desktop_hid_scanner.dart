import 'package:hid_tool/hid_tool.dart';

import '../hid_scanner.dart';

/// Desktop discovery: silent enumeration.
///
/// `hid_tool` already unifies transport across platforms; the only thing that
/// differs is how a [HidDevice] handle is obtained. On desktop we enumerate
/// silently via `Hid.getDevices()`.
class DesktopHidScanner implements HidScanner {
  const DesktopHidScanner();

  @override
  Future<List<HidDevice>> scan(List<DeviceFilter> filters) async {
    // Desktop has no grant model: enumerate silently and filter.
    return _enumerate(filters);
  }

  @override
  Future<List<HidDevice>> getAuthorized(List<DeviceFilter> filters) async {
    // On desktop there is no authorization state, so this is identical to scan.
    return _enumerate(filters);
  }

  Future<List<HidDevice>> _enumerate(List<DeviceFilter> filters) async {
    final devices = await Hid.getDevices();

    final matches = <HidDevice>[];
    for (final device in devices) {
      if (_matchesAny(device, filters)) {
        matches.add(device);
      }
    }
    return matches;
  }

  bool _matchesAny(HidDevice device, List<DeviceFilter> filters) {
    if (filters.isEmpty) return true;
    for (final f in filters) {
      if ((f.vendorId == null || device.vendorId == f.vendorId) &&
          (f.productId == null || device.productId == f.productId) &&
          (f.usagePage == null || device.usagePage == f.usagePage) &&
          (f.usage == null || device.usage == f.usage)) {
        return true;
      }
    }
    return false;
  }
}
