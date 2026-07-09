import 'dart:async';

import 'package:driver_hub/core/device/device_scanner.dart';
import 'package:driver_hub/core/device/discovered_device.dart';
import 'package:driver_hub/core/device/hid_session.dart';
import 'package:driver_hub/core/hid/hid_events.dart';

import '../protocol/device_protocol.dart';
import 'device_session.dart';

/// Callback for a session that connected (or reconnected) and verified.
typedef DeviceSessionCallback = void Function(DeviceSession session);

/// Callback for a session that disconnected.
typedef DeviceDisconnectCallback = void Function(int vendorId, int productId);

/// Watches HID connect/disconnect events and manages session lifecycle.
///
/// On disconnect of a known device: disposes its [DeviceSession].
/// On connect of a supported device: re-acquires it gesture-free via
/// [DeviceScanner.discoverAuthorized], re-opens, re-runs handshake/verify.
///
/// No retry loop, no backoff — one action per event.
/// First-ever connect of a web device is NOT handled here; that requires a user
/// gesture (the [DeviceScanner.discover] path) and stays a manual scan.
class DeviceWatcher {
  final DeviceScanner _scanner;
  final DeviceProtocol Function() _protocolFactory;
  final HidSession Function(DiscoveredDevice) _sessionFactory;
  final DeviceSession Function({
    required DiscoveredDevice device,
    required HidSession session,
    required DeviceProtocol protocol,
  }) _sessionCtor;

  final HidEvents _events = HidEvents();
  final _sessions = <_DeviceKey, DeviceSession>{};

  DeviceWatcher({
    required this._scanner,
    required this._protocolFactory,
    required this._sessionFactory,
    required this._sessionCtor,
  });

  /// Starts watching. [onConnect] fires when a device (re)connects and
  /// verifies; [onDisconnect] when one is removed.
  void start({
    required DeviceSessionCallback onConnect,
    required DeviceDisconnectCallback onDisconnect,
  }) {
    _events.start(
      onConnect: (vid, pid) => _handleConnect(vid, pid, onConnect),
      onDisconnect: (vid, pid) => _handleDisconnect(vid, pid, onDisconnect),
    );
  }

  /// Stops watching and disposes all active sessions.
  Future<void> stop() async {
    _events.stop();
    for (final session in _sessions.values) {
      await session.dispose();
    }
    _sessions.clear();
  }

  /// Registers an already-started session so its disconnect is tracked.
  void register(DeviceSession session) {
    final key = _DeviceKey(session.device.mode.vid, session.device.mode.pid);
    _sessions[key] = session;
  }

  Future<void> _handleConnect(
    int vid,
    int pid,
    DeviceSessionCallback onConnect,
  ) async {
    final key = _DeviceKey(vid, pid);
    if (_sessions.containsKey(key)) return; // already active

    final discovered = await _scanner.discoverAuthorized();
    DiscoveredDevice? match;
    for (final d in discovered) {
      if (d.mode.vid == vid && d.mode.pid == pid) {
        match = d;
        break;
      }
    }
    if (match == null) return; // not a supported device

    final session = _sessionCtor(
      device: match,
      session: _sessionFactory(match),
      protocol: _protocolFactory(),
    );
    // Register only after verify; rejected sessions are closed and discarded.
    final verified = await session.start();
    if (!verified) {
      await session.dispose();
      return;
    }
    _sessions[key] = session;
    onConnect(session);
  }

  Future<void> _handleDisconnect(
    int vid,
    int pid,
    DeviceDisconnectCallback onDisconnect,
  ) async {
    final key = _DeviceKey(vid, pid);
    final session = _sessions.remove(key);
    if (session != null) {
      await session.dispose();
    }
    onDisconnect(vid, pid);
  }
}

class _DeviceKey {
  final int vid, pid;
  const _DeviceKey(this.vid, this.pid);
  @override
  bool operator ==(Object other) =>
      other is _DeviceKey && vid == other.vid && pid == other.pid;
  @override
  int get hashCode => Object.hash(vid, pid);
}
