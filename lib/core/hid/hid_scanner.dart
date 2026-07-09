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

  /// Returns previously-authorized devices matching [filters], with no user
  /// gesture and no prompt.
  ///
  /// On web this calls `navigator.hid.getDevices()` — only devices the user
  /// already granted (via [scan]) are returned. A never-granted device is not
  /// returned here; it requires [scan] (a user gesture) first.
  ///
  /// Used for reconnect: a device unplugged and replugged is re-acquired here
  /// without re-prompting. On desktop this is equivalent to [scan] (no grant
  /// model), since the OS exposes all connected devices.
  Future<List<HidDevice>> getAuthorized(List<DeviceFilter> filters);
}
