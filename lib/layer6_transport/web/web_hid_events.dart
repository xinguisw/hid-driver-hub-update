// Web-only JS interop for WebHID connect/disconnect events.
//
// hid_tool receives these events internally but does not expose them. This file
// binds navigator.hid.addEventListener directly via dart:js_interop so the
// reconnect watcher can hear connect/disconnect on web.
//
// Selected via the conditional import in hid_events.dart.
import 'dart:js_interop';

import '../hid_event_handle.dart';

@JS('navigator.hid')
external _Hid? get _navigatorHid;

@JS('HID')
extension type _Hid._(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}

@JS('HIDConnectionEvent')
extension type _HidConnectionEvent._(JSObject _) implements JSObject {
  external _HidDevice get device;
}

@JS('Device')
extension type _HidDevice._(JSObject _) implements JSObject {
  external int get vendorId;
  external int get productId;
}

/// Returns navigator.hid, or null if WebHID is unavailable.
_Hid? _getNavigatorHid() => _navigatorHid;

/// Synthesizes the device path hid_tool reports for a web [HidDevice]
/// (`web:<vid>:<pid>`), so connect/disconnect events match the path on a
/// [DiscoveredDevice.hidDevice]. WebHID has no inherent per-instance id; two
/// identical web mice share this path (a hid_tool limitation).
String _pathFor(int vendorId, int productId) => 'web:$vendorId:$productId';

/// Starts listening to web connect/disconnect events.
///
/// Each callback receives (path, vendorId, productId). Returns a handle whose
/// [stop] removes the listeners.
HidEventSubscription startWebHidListeners({
  required void Function(String path, int vendorId, int productId) onConnect,
  required void Function(String path, int vendorId, int productId) onDisconnect,
}) {
  final hid = _getNavigatorHid();
  if (hid == null) {
    return const HidEventSubscription.noop();
  }

  void connectHandler(_HidConnectionEvent e) {
    final vid = e.device.vendorId;
    final pid = e.device.productId;
    onConnect(_pathFor(vid, pid), vid, pid);
  }

  void disconnectHandler(_HidConnectionEvent e) {
    final vid = e.device.vendorId;
    final pid = e.device.productId;
    onDisconnect(_pathFor(vid, pid), vid, pid);
  }

  final c = connectHandler.toJS;
  final d = disconnectHandler.toJS;
  hid.addEventListener('connect', c);
  hid.addEventListener('disconnect', d);

  return HidEventSubscription(() {
    hid.removeEventListener('connect', c);
    hid.removeEventListener('disconnect', d);
  });
}
