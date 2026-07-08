import 'dart:async';

import 'package:driver_hub/core/device/discovered_device.dart';
import 'package:driver_hub/core/device/hid_session.dart';

import '../protocol/device_protocol.dart';

/// State of a device session, emitted to the card.
class DeviceSessionState {
  final String name;
  final String mode;
  final Status status;
  final String? error;

  const DeviceSessionState._({
    required this.name,
    required this.mode,
    required this.status,
    this.error,
  });

  factory DeviceSessionState.connecting(String name, String mode) =>
      DeviceSessionState._(name: name, mode: mode, status: Status.connecting);
  factory DeviceSessionState.verified(String name, String mode) =>
      DeviceSessionState._(name: name, mode: mode, status: Status.verified);
  factory DeviceSessionState.rejected(String name, String mode) =>
      DeviceSessionState._(name: name, mode: mode, status: Status.rejected);
  factory DeviceSessionState.error(String name, String mode, String msg) =>
      DeviceSessionState._(
          name: name, mode: mode, status: Status.error, error: msg);
}

enum Status { connecting, verified, rejected, error }

/// Per-device orchestrator: open -> handshake -> verify against the catalog.
///
/// Match loads name and mode for the card; mismatch closes the session.
/// Battery/charging need OSD push parsing and are added later.
class DeviceSession {
  final DiscoveredDevice device;
  final HidSession _session;
  final DeviceProtocol _protocol;

  final _controller = StreamController<DeviceSessionState>.broadcast();

  DeviceSession({
    required this.device,
    required this._session,
    required this._protocol,
  });

  Stream<DeviceSessionState> get state => _controller.stream;

  /// Runs open -> handshake -> verify. Emits state on [state].
  Future<void> start() async {
    final name = device.entry.model;
    final mode = device.mode.desc;

    _controller.add(DeviceSessionState.connecting(name, mode));

    try {
      await _session.open();
      final hs = await _protocol.handshake(_session);

      final ok = hs.deviceType == device.entry.deviceType &&
          hs.deviceId == device.entry.devId;

      if (ok) {
        _controller.add(DeviceSessionState.verified(name, mode));
      } else {
        await _session.close();
        _controller.add(DeviceSessionState.rejected(name, mode));
      }
    } catch (e) {
      await _safeClose();
      _controller.add(DeviceSessionState.error(name, mode, e.toString()));
    }
  }

  Future<void> dispose() async {
    await _safeClose();
    await _controller.close();
  }

  Future<void> _safeClose() async {
    try {
      await _session.close();
    } catch (_) {}
  }
}
