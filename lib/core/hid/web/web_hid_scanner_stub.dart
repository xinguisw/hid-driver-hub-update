// Stub for non-web platforms. The real implementation lives in
// web_hid_scanner.dart and is selected via the conditional import in
// hid_scanner_factory.dart. This file must expose the same public symbol so
// the factory compiles on desktop/mobile.
import 'package:hid_tool/hid_tool.dart';

import '../hid_scanner.dart';

class WebHidScanner implements HidScanner {
  const WebHidScanner();

  @override
  Future<List<HidDevice>> scan(List<DeviceFilter> filters) {
    throw UnsupportedError('WebHidScanner is only available on web.');
  }
}
