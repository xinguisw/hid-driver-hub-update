// Web-only connect/disconnect events using flutter_webhid streams.
//
// Selected via the conditional import in hid_events.dart.
import 'package:flutter_webhid/flutter_webhid.dart';

import '../hid_event_handle.dart';

int _primaryUsagePage(Device dev) {
  for (final c in dev.collections) {
    if (c.usagePage >= 0xFF00) return c.usagePage;
  }
  return dev.collections.isNotEmpty ? dev.collections.first.usagePage : 0;
}

/// Synthesizes the device path reported for a web device (`web:<vid>:<pid>:<usagePage>`).
String _pathFor(int vendorId, int productId, int usagePage) =>
    'web:$vendorId:$productId:${usagePage.toRadixString(16)}';

/// Starts listening to web connect/disconnect events via flutter_webhid.
///
/// Each callback receives (path, vendorId, productId). Returns a handle whose
/// [stop] removes the listeners.
HidEventSubscription startWebHidListeners({
  required void Function(String path, int vendorId, int productId) onConnect,
  required void Function(String path, int vendorId, int productId) onDisconnect,
}) {
  if (!WebHID.isSupported || WebHID.instance == null) {
    return const HidEventSubscription.noop();
  }

  final webHid = WebHID.instance!;
  final connectSub = webHid.onConnect.listen((event) {
    final dev = event.device;
    final page = _primaryUsagePage(dev);
    onConnect(_pathFor(dev.vendorId, dev.productId, page), dev.vendorId, dev.productId);
  });

  final disconnectSub = webHid.onDisconnect.listen((event) {
    final dev = event.device;
    final page = _primaryUsagePage(dev);
    onDisconnect(_pathFor(dev.vendorId, dev.productId, page), dev.vendorId, dev.productId);
  });

  return HidEventSubscription(() {
    connectSub.cancel();
    disconnectSub.cancel();
  });
}


