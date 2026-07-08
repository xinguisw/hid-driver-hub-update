import 'package:flutter/foundation.dart';

import 'hid_scanner.dart';
import 'desktop/desktop_hid_scanner.dart';
import 'web/web_hid_scanner_stub.dart'
    if (dart.library.html) 'web/web_hid_scanner.dart'
    as web;

/// The single platform seam in the application.
///
/// The only place that decides desktop vs web. Everything above this
/// (DeviceScanner, HidSession, features) is platform-blind.
class HidScannerFactory {
  HidScannerFactory._();

  /// The scanner for the current platform.
  ///
  /// Desktop -> [DesktopHidScanner] (silent enumeration).
  /// Web     -> [WebHidScanner] (interactive permission picker).
  static HidScanner current() {
    if (kIsWeb) {
      return web.WebHidScanner();
    }
    return DesktopHidScanner();
  }
}
