import 'dart:async';

import 'package:driver_hub/core/device/discovered_device.dart';
import 'package:driver_hub/core/device/hid_session.dart';
import 'package:flutter/foundation.dart';

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

  /// Whether the underlying transport is still open. False once the device
  /// unplugs or [dispose] runs. Callers should check before issuing queries.
  bool get isAlive => _session.isOpen;

  /// Pass-through to the protocol's battery query (opcode A4).
  /// Returns null if the session is no longer alive (device gone) rather than
  /// throwing into a dead transport.
  Future<BatteryResult?> queryBattery() async {
    if (!isAlive) return null;
    return _protocol.queryBattery(_session);
  }

  /// Pass-through to the protocol's firmware query (opcode A8).
  /// Returns null if the session is no longer alive (device gone).
  Future<FirmwareResult?> queryFirmware() async {
    if (!isAlive) return null;
    return _protocol.queryFirmware(_session);
  }

  /// Runs open -> handshake -> verify. Emits state on [state].
  // Returns true only when verified; false on reject or error.
  Future<bool> start() async {
    final name = device.entry.model;
    final mode = device.mode.desc;

    _controller.add(DeviceSessionState.connecting(name, mode));
    debugPrint('[session] start: devId=${device.entry.devId} '
        'expected deviceType=${device.entry.deviceType.name} expected devId="${device.entry.devId}"');

    try {
      debugPrint('[session] opening device…');
      await _session.open();
      debugPrint('[session] opened, running handshake…');
      final hs = await _protocol.handshake(_session);

      final typeMatch = hs.deviceType == device.entry.deviceType;
      final idMatch = hs.deviceId == device.entry.devId;
      debugPrint('[session] verify: reported type=${hs.deviceType?.name ?? 'unknown'} '
          '(match=$typeMatch), reported id="${hs.deviceId}" (match=$idMatch)');

      if (typeMatch && idMatch) {
        debugPrint('[session] VERIFIED');
        _controller.add(DeviceSessionState.verified(name, mode));
        return true;
      }
      debugPrint('[session] REJECTED — closing');
      await _session.close();
      _controller.add(DeviceSessionState.rejected(name, mode));
      return false;
    } catch (e) {
      debugPrint('[session] ERROR: $e');
      await _safeClose();
      _controller.add(DeviceSessionState.error(name, mode, e.toString()));
      return false;
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
