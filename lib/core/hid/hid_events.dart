import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hid_tool/hid_tool.dart';

import 'hid_event_handle.dart';
import 'web/web_hid_events_stub.dart'
    if (dart.library.js_interop) 'web/web_hid_events.dart'
    as webevents;

/// Unified connect/disconnect event source across desktop and web.
///
/// Desktop: hid_tool's [HidDeviceEvents] (method-channel, dart:io).
/// Web: direct navigator.hid listeners via dart:js_interop — hid_tool does not
/// expose these publicly, so we bind them ourselves.
///
/// Both deliver (vendorId, productId). The watcher matches these against its
/// known device set.
class HidEvents {
  StreamSubscription<HidDeviceEvent>? _desktopConnect;
  StreamSubscription<HidDeviceEvent>? _desktopDisconnect;
  HidEventSubscription? _webSub;

  /// Start listening. Call [stop] to tear down.
  void start({
    required void Function(int vendorId, int productId) onConnect,
    required void Function(int vendorId, int productId) onDisconnect,
  }) {
    if (kIsWeb) {
      _webSub = webevents.startWebHidListeners(
        onConnect: onConnect,
        onDisconnect: onDisconnect,
      );
    }
    else {
      Hid.startListening();
      _desktopConnect = HidDeviceEvents.onConnected.listen((e) {
        if (e.vendorId != null && e.productId != null) {
          onConnect(e.vendorId!, e.productId!);
        }
      });
      _desktopDisconnect = HidDeviceEvents.onDisconnected.listen((e) {
        if (e.vendorId != null && e.productId != null) {
          onDisconnect(e.vendorId!, e.productId!);
        }
      });
    }
  }

  /// Stop listening and release resources.
  void stop() {
    _webSub?.stop();
    _webSub = null;
    _desktopConnect?.cancel();
    _desktopDisconnect?.cancel();
    _desktopConnect = null;
    _desktopDisconnect = null;
    if (!kIsWeb) {
      Hid.stopListening();
    }
  }
}
