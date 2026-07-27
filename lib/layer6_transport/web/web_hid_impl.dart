import 'dart:js_interop';

import 'package:hid_tool/hid_tool.dart';

import '../hid_scanner.dart';

/// Web discovery: interactive browser permission picker.
///
/// Browsers cannot silently enumerate HID devices. The user must grant access
/// via a picker triggered by a user gesture. `requestDevice` shows that picker;
/// devices the user previously authorized are returned without re-prompting.
///
/// Catalog [usagePage] is enforced here from WebHID `collections` (available
/// without open). hid_tool reports usagePage/interfaceNumber as 0 on web.
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
    return await _filter(devices, filters);
  }

  @override
  Future<List<HidDevice>> getAuthorized(List<DeviceFilter> filters) async {
    // Gesture-free: returns only previously-granted devices. No prompt.
    final devices = await Hid.getDevices();
    return await _filter(devices, filters);
  }

  /// VID/PID from [filters], plus catalog usagePage via WebHID collections.
  ///
  /// hid_tool wraps each JS HIDDevice but exposes usagePage=0; collections are
  /// read with a second navigator.hid.getDevices() aligned by index (same call
  /// order as the browser list hid_tool just wrapped).
  Future<List<HidDevice>> _filter(
    List<HidDevice> devices,
    List<DeviceFilter> filters,
  ) async {
    if (devices.isEmpty) return devices;

    final jsMeta = await _jsDeviceMeta();
    final out = <HidDevice>[];
    for (var i = 0; i < devices.length; i++) {
      final d = devices[i];
      final meta = i < jsMeta.length ? jsMeta[i] : null;
      if (_matchesFilter(d, meta, filters)) {
        out.add(d);
      }
    }
    return out;
  }

  bool _matchesFilter(
    HidDevice d,
    _JsHidMeta? meta,
    List<DeviceFilter> filters,
  ) {
    if (filters.isEmpty) {
      return true;
    }
    for (final f in filters) {
      if (f.vendorId != null && d.vendorId != f.vendorId) continue;
      if (f.productId != null && d.productId != f.productId) continue;
      // Catalog usagePage: require it in this handle's collections when known.
      if (f.usagePage != null) {
        if (meta == null) continue;
        if (meta.vendorId != d.vendorId || meta.productId != d.productId) {
          continue;
        }
        if (!meta.usagePages.contains(f.usagePage)) continue;
      }
      return true;
    }
    return false;
  }
}

class _JsHidMeta {
  final int vendorId;
  final int productId;
  final Set<int> usagePages;
  const _JsHidMeta({
    required this.vendorId,
    required this.productId,
    required this.usagePages,
  });
}

@JS('navigator.hid')
external _NavHid? get _navigatorHid;

@JS('HID')
extension type _NavHid._(JSObject _) implements JSObject {
  external JSPromise<JSArray<_JsHidDevice>> getDevices();
}

@JS('HIDDevice')
extension type _JsHidDevice._(JSObject _) implements JSObject {
  external int get vendorId;
  external int get productId;
  external JSArray<_JsCollection> get collections;
}

@JS()
extension type _JsCollection._(JSObject _) implements JSObject {
  external int get usagePage;
}

Future<List<_JsHidMeta>> _jsDeviceMeta() async {
  final hid = _navigatorHid;
  if (hid == null) return const [];
  final list = (await hid.getDevices().toDart).toDart;
  return list.map((d) {
    final pages = <int>{};
    for (final c in d.collections.toDart) {
      pages.add(c.usagePage);
    }
    return _JsHidMeta(
      vendorId: d.vendorId,
      productId: d.productId,
      usagePages: pages,
    );
  }).toList();
}
