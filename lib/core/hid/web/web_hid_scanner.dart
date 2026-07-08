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
    return Hid.requestDevice(filters: filters);
  }
}
