import 'package:hid_tool/hid_tool.dart';

import '../hid_scanner.dart';

/// Web discovery: interactive browser permission picker.
///
/// Browsers cannot silently enumerate HID devices. The user must grant access
/// via a picker triggered by a user gesture. `requestDevice` shows that picker;
/// devices the user previously authorized are returned without re-prompting.
///
/// This file is only compiled on web (see the conditional import in
/// `hid_scanner_factory.dart`). On other platforms a stub is used.
class WebHidScanner implements HidScanner {
  const WebHidScanner();

  @override
  Future<List<HidDevice>> scan(List<DeviceFilter> filters) async {
    if (!Hid.isWebHIDSupported) {
      throw UnsupportedError(
        'WebHID is not supported in this browser. Use Chrome or Edge over '
        'HTTPS or localhost.',
      );
    }
    // requestDevice requires a user gesture in the browser. Callers should
    // invoke discover() from a tap handler; otherwise the browser rejects it.
    final devices = await Hid.requestDevice(filters: filters);
    return _filter(devices, filters);
  }

  @override
  Future<List<HidDevice>> getAuthorized(List<DeviceFilter> filters) async {
    // Gesture-free: returns only previously-granted devices. No prompt.
    // Used by the reconnect path so a replugged device is re-acquired without
    // re-asking the user. A never-granted device is not returned here.
    final devices = await Hid.getDevices();
    return _filter(devices, filters);
  }

  List<HidDevice> _filter(List<HidDevice> devices, List<DeviceFilter> filters) {
    if (filters.isEmpty) return devices;
    // hid_tool reports usagePage/usage as 0 on web (see HidDeviceWeb), so match
    // on VID/PID only. The picker already enforced usagePage at grant time.
    return devices.where((d) {
      for (final f in filters) {
        if ((f.vendorId == null || d.vendorId == f.vendorId) &&
            (f.productId == null || d.productId == f.productId)) {
          return true;
        }
      }
      return false;
    }).toList();
  }
}
