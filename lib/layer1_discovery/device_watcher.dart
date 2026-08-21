import 'dart:async';

import 'package:driver_hub/layer1_discovery/device_scanner.dart';
import 'package:driver_hub/layer1_discovery/discovered_device.dart';
import 'package:driver_hub/layer6_transport/hid_session.dart';
import 'package:driver_hub/layer6_transport/hid_events.dart';

import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'device_session.dart';

/// Callback for a session that connected (or reconnected) and verified.
typedef DeviceSessionCallback = void Function(DeviceSession session);

/// Callback for a session that disconnected.
typedef DeviceDisconnectCallback = void Function(String path, int vendorId, int productId);

/// Watches HID connect/disconnect events and manages session lifecycle.
///
/// Sessions are keyed by the device [path] (hidapi path on desktop, synthesized
/// `web:<vid>:<pid>` on web), not by (vid, pid). This distinguishes two
/// identical mice on desktop, where each gets a unique path. On web, hid_tool
/// itself collapses identical mice to one path, so they remain
/// indistinguishable there — a hid_tool limitation, not a watcher one.
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

  final HidEvents _events;
  final _sessions = <String, DeviceSession>{}; // keyed by device path

  /// Disconnect teardown is deferred by [_replugDebounce]. If the same path
  /// reconnects within the window, [_handleConnect] cancels the pending timer
  /// so [onDisconnect] never fires (the card does not flicker), then disposes
  /// the orphaned session before opening a fresh one.
  static const Duration _replugDebounce = Duration(milliseconds: 300);
  final _pendingDisposes = <String, Timer>{};

  /// Sessions pulled from [_sessions] whose dispose is still deferred.
  // why: cancelling the debounce timer skips its dispose, leaving the session's
  // input subscription and HID handle open.
  final _pendingOrphans = <String, DeviceSession>{};

  DeviceWatcher({
    required this._scanner,
    required this._protocolFactory,
    required this._sessionFactory,
    required this._sessionCtor,
    // why: connect/disconnect events are the only dependency this class built
    // itself; injecting lets a test drive the lifecycle without hardware.
    HidEvents? events,
  }) : _events = events ?? HidEvents();

  /// Starts watching. [onConnect] fires when a device (re)connects and
  /// verifies; [onDisconnect] when one is removed.
  void start({
    required DeviceSessionCallback onConnect,
    required DeviceDisconnectCallback onDisconnect,
  }) {
    _events.start(
      onConnect: (path, vid, pid) => _handleConnect(path, vid, pid, onConnect),
      onDisconnect: (path, vid, pid) =>
          _handleDisconnect(path, vid, pid, onDisconnect),
    );
  }

  /// Stops watching and disposes all active sessions.
  Future<void> stop() async {
    _events.stop();
    for (final t in _pendingDisposes.values) {
      t.cancel();
    }
    _pendingDisposes.clear();
    for (final orphan in _pendingOrphans.values) {
      await orphan.dispose();
    }
    _pendingOrphans.clear();
    for (final session in _sessions.values) {
      await session.dispose();
    }
    _sessions.clear();
  }

  /// Registers an already-started session so its disconnect is tracked.
  void register(DeviceSession session) {
    _sessions[session.device.hidDevice.path] = session;
  }

  DeviceSession? getSession(String path) => _sessions[path];
  bool hasSession(String path) => _sessions.containsKey(path);

  Future<void> _handleConnect(
    String path,
    int vid,
    int pid,
    DeviceSessionCallback onConnect,
  ) async {
    if (_sessions.containsKey(path)) return; // already active
    // Cancel any pending dispose for this path (rapid replug).
    _pendingDisposes.remove(path)?.cancel();
    // why: awaited so the old handle closes before the new open() on the same
    // path. A second open while the first is live can be rejected.
    await _pendingOrphans.remove(path)?.dispose();

    final discovered = await _scanner.discoverAuthorized();
    DiscoveredDevice? match;
    for (final d in discovered) {
      // Match the specific instance by path. On desktop the path is unique per
      // device, so a second identical mouse is matched here, not ignored.
      if (d.hidDevice.path == path) {
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
    _sessions[path] = session;
    onConnect(session);
  }

  Future<void> _handleDisconnect(
    String path,
    int vid,
    int pid,
    DeviceDisconnectCallback onDisconnect,
  ) async {
    final session = _sessions.remove(path);
    // Defer teardown by [_replugDebounce]; reconnect cancels it.
    _pendingDisposes[path]?.cancel();
    if (session != null) {
      _pendingOrphans[path] = session;
    }
    _pendingDisposes[path] = Timer(_replugDebounce, () {
      _pendingDisposes.remove(path);
      final orphan = _pendingOrphans.remove(path);
      onDisconnect(path, vid, pid);
      orphan?.dispose(); // best-effort; close() aborts in-flight receives
    });
  }
}
