import 'package:hid_tool/hid_tool.dart';

/// The single HID discovery contract.
///
/// This is the ONLY concern in the application that is split by platform,
/// because discovery behaves differently on desktop (silent enumeration) and
/// web (browser-enforced permission picker). Transport is NOT split — see
/// [HidSession].
///
/// Two implementations sit behind this interface:
/// - [DesktopHidScanner] — uses `Hid.getDevices()` (silent).
/// - [WebHidScanner]      — uses `Hid.requestDevice()` (interactive picker).
///
/// Obtain the correct one for the current platform via [HidScanner.current].
/// Nothing outside `core/hid/` may call `Hid.getDevices` / `Hid.requestDevice`
/// directly or branch on `kIsWeb`.
abstract class HidScanner {
  /// Returns the HID devices the user has granted access to and that match
  /// [filters].
  ///
  /// On desktop this enumerates silently. On web this may present a browser
  /// permission picker; devices the user previously authorized are returned
  /// without re-prompting.
  Future<List<HidDevice>> scan(List<DeviceFilter> filters);
}
