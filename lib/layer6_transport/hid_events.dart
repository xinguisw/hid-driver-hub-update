import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hid_tool/hid_tool.dart';

import 'hid_event_handle.dart';
import 'web/web_hid_events_stub.dart'
    if (dart.library.js_interop) 'web/web_hid_events.dart'
    as webevents;

/// Unified connect/disconnect event source across desktop and web.
///
/// Desktop: hid_tool's [HidDeviceEvents] (method-channel, dart:io). Each event
/// carries a unique device [path] (the hidapi path), so two identical mice are
/// distinguishable.
/// Web: direct navigator.hid listeners via dart:js_interop — hid_tool does not
/// expose these publicly, so we bind them ourselves. WebHID has no inherent
/// per-instance id; we synthesize `web:<vid>:<pid>` to match the path hid_tool
/// reports for a [HidDevice]. Two identical web mice share that path (a
/// hid_tool limitation), but it is still the most stable key available.
///
/// Both deliver the device [path], which the watcher matches against its known
/// device set. (vid, pid) is also carried for logging and unsupported-device
/// filtering.
class HidEvents {
  StreamSubscription<HidDeviceEvent>? _desktopConnect;
  StreamSubscription<HidDeviceEvent>? _desktopDisconnect;
  HidEventSubscription? _webSub;

  /// Start listening. Call [stop] to tear down.
  void start({
    required void Function(String path, int vendorId, int productId) onConnect,
    required void Function(String path, int vendorId, int productId) onDisconnect,
  }) {
    if (kIsWeb) {
      _webSub = webevents.startWebHidListeners(
        onConnect: onConnect,
        onDisconnect: onDisconnect,
      );
    }
    else {
      try {
        Hid.startListening().catchError((e) {
          debugPrint('Failed to start HID listening (expected in tests): $e');
        });
      } catch (e) {
        debugPrint('Failed to start HID listening synchronously: $e');
      }
      _desktopConnect = HidDeviceEvents.onConnected.listen((e) {
        if (e.vendorId != null && e.productId != null) {
          onConnect(e.path, e.vendorId!, e.productId!);
        }
      });
      _desktopDisconnect = HidDeviceEvents.onDisconnected.listen((e) {
        if (e.vendorId != null && e.productId != null) {
          onDisconnect(e.path, e.vendorId!, e.productId!);
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
      try {
        Hid.stopListening().catchError((e) {
          debugPrint('Failed to stop HID listening (expected in tests): $e');
        });
      } catch (e) {
        debugPrint('Failed to stop HID listening synchronously: $e');
      }
    }
  }
}
