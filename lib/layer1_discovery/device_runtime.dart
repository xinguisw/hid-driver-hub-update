import 'dart:convert';

import 'package:driver_hub/layer1_discovery/device_scanner.dart';
import 'package:driver_hub/layer1_discovery/device_settings_gateway.dart';
import 'package:driver_hub/layer1_discovery/device_session.dart';
import 'package:driver_hub/layer1_discovery/device_watcher.dart';
import 'package:driver_hub/layer1_discovery/discovered_device.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:driver_hub/layer6_transport/hid_session.dart';
import 'package:driver_hub/layer6_transport/local_storage.dart';
import 'package:flutter/foundation.dart';

/// L1 lifecycle boundary used by L4 to discover verified device sessions.
///
/// L4 requests device lifecycle work through this port. The concrete runtime
/// keeps scanner, watcher, protocol, and HID-session construction in L1/L6.
abstract interface class DeviceRuntime {
  Future<List<DiscoveredDevice>> discoverAuthorized();

  Future<List<DiscoveredDevice>> discover();

  Future<DeviceSettingsGateway?> openAndRegister(DiscoveredDevice device);

  void startWatching({
    required DeviceGatewayConnectCallback onConnect,
    required DeviceDisconnectCallback onDisconnect,
  });

  Future<void> stop();
}

/// Production implementation of [DeviceRuntime].
class LiveDeviceRuntime implements DeviceRuntime {
  factory LiveDeviceRuntime() {
    final scanner = DeviceScanner();
    final watcher = DeviceWatcher(
      scanner: scanner,
      protocolFactory: () => const MouseProtocol(),
      sessionFactory: (device) => HidSession(device.hidDevice),
      sessionCtor: DeviceSession.new,
    );
    return LiveDeviceRuntime._(scanner, watcher);
  }

  LiveDeviceRuntime._(this._scanner, this._watcher);

  final DeviceScanner _scanner;
  final DeviceWatcher _watcher;

  @override
  Future<List<DiscoveredDevice>> discoverAuthorized() =>
      _scanner.discoverAuthorized();

  @override
  Future<List<DiscoveredDevice>> discover() => _scanner.discover();

  @override
  Future<DeviceSettingsGateway?> openAndRegister(
    DiscoveredDevice device,
  ) async {
    final session = DeviceSession(
      device: device,
      session: HidSession(device.hidDevice),
      protocol: const MouseProtocol(),
    );
    if (!await session.start()) {
      await session.dispose();
      return null;
    }
    _saveLastDeviceHint(device);
    _watcher.register(session);
    return session;
  }

  void _saveLastDeviceHint(DiscoveredDevice device) {
    if (!kIsWeb) return;
    try {
      writeLocalStorage(
        _lastHidKey,
        jsonEncode({
          'vendorId': device.mode.vid,
          'productId': device.mode.pid,
          'productName': device.entry.model,
        }),
      );
    } catch (_) {
      // The hint is non-critical and unavailable in some browser contexts.
    }
  }

  @override
  void startWatching({
    required DeviceGatewayConnectCallback onConnect,
    required DeviceDisconnectCallback onDisconnect,
  }) {
    _watcher.start(
      onConnect: (session) {
        _saveLastDeviceHint(session.device);
        onConnect(session);
      },
      onDisconnect: onDisconnect,
    );
  }

  @override
  Future<void> stop() => _watcher.stop();
}

const _lastHidKey = 'driver_hub.lastHid';
