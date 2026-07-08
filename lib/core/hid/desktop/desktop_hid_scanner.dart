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
    // hid_tool's getDevices accepts a single filter; enumerate broadly then
    // narrow by the catalog-driven filters. Most desktop HID stacks return
    // the full device set, so we filter in Dart to honor every catalog mode.
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
