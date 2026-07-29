import 'dart:async';

import 'package:driver_hub/layer1_discovery/discovered_device.dart';
import 'package:driver_hub/layer6_transport/hid_session.dart';
import 'package:flutter/foundation.dart';

import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:driver_hub/layer5_codec/codecs/osd_codec.dart';

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
class DeviceSession {
  /// Max transport open attempts per [start] (total tries).
  static const int maxOpenAttempts = 2;

  /// Delay between failed open attempts.
  static const Duration openRetryDelay = Duration(milliseconds: 120);

  /// Max handshake (identity read) attempts per [start] (total tries).
  static const int maxHandshakeAttempts = 2;

  /// Delay between failed handshake attempts.
  static const Duration handshakeRetryDelay = Duration(milliseconds: 120);

  final DiscoveredDevice device;
  final HidSession _session;
  final DeviceProtocol _protocol;
  final OsdCodec _osd = const OsdCodec();

  final _controller = StreamController<DeviceSessionState>.broadcast();
  final _batteryPushes = StreamController<BatteryResult>.broadcast();
  StreamSubscription<Uint8List>? _unsolicitedSub;

  DeviceSession({
    required this.device,
    required this._session,
    required this._protocol,
  });

  Stream<DeviceSessionState> get state => _controller.stream;

  /// OSD report 9 opcode 2 (and web short frames) parsed to battery.
  Stream<BatteryResult> get batteryPushes => _batteryPushes.stream;

  /// Whether the underlying transport is still open.
  bool get isAlive => _session.isOpen;

  /// Re-run A1 handshake on an open session.
  ///
  /// Firmware NAKs onboard config (reason 0x01) if handshake is not fresh
  /// when settings opens later. Does not re-open the device.
  Future<bool> rehandshake() async {
    if (!isAlive) return false;
    final name = device.entry.model;
    final mode = device.mode.desc;
    try {
      debugPrint('[session] rehandshake: $name…');
      final hs = await _protocol.handshake(_session);
      final typeMatch = hs.deviceType == device.entry.deviceType;
      final idMatch = hs.deviceId == device.entry.devId;
      debugPrint('[session] rehandshake: type=${hs.deviceType?.name} '
          'id="${hs.deviceId}" match=${typeMatch && idMatch}');
      if (typeMatch && idMatch) {
        return true;
      }
      _controller.add(DeviceSessionState.rejected(name, mode));
      return false;
    } catch (e) {
      debugPrint('[session] rehandshake ERROR: $e');
      return false;
    }
  }

  Future<BatteryResult?> queryBattery() async {
    if (!isAlive) return null;
    return _protocol.queryBattery(_session);
  }

  Future<FirmwareResult?> queryFirmware() async {
    if (!isAlive) return null;
    return _protocol.queryFirmware(_session);
  }

  Future<ButtonMappingResult?> queryButtonMapping() async {
    if (!isAlive) return null;
    return _protocol.queryButtonMapping(_session);
  }

  /// Thin L1 forwarder for B2 SET (L5 encodes + CRC).
  Future<void> setButtonMapping(List<ButtonMappingEntry> buttons) async {
    if (!isAlive) {
      throw StateError('setButtonMapping: session not alive');
    }
    await _protocol.setButtonMapping(_session, buttons);
  }

  Future<ReportRateDpiInfoResult?> queryReportRateDpiInfo() async {
    if (!isAlive) return null;
    return _protocol.queryReportRateDpiInfo(_session);
  }

  Future<DpiTableResult?> queryDpiTable() async {
    if (!isAlive) return null;
    return _protocol.queryDpiTable(_session);
  }

  Future<DpiRgbResult?> queryDpiRgb() async {
    if (!isAlive) return null;
    return _protocol.queryDpiRgb(_session);
  }

  Future<SensorOtherResult?> querySensorOther() async {
    if (!isAlive) return null;
    return _protocol.querySensorOther(_session);
  }

  Future<RgbBacklightResult?> queryRgbBacklight() async {
    if (!isAlive) return null;
    return _protocol.queryRgbBacklight(_session);
  }

  /// Open (with retry) -> handshake -> verify. Starts OSD unsolicited when verified.
  Future<bool> start() async {
    final name = device.entry.model;
    final mode = device.mode.desc;

    _controller.add(DeviceSessionState.connecting(name, mode));
    debugPrint('[session] start: devId=${device.entry.devId} '
        'expected deviceType=${device.entry.deviceType.name} expected devId="${device.entry.devId}"');

    try {
      await _openTransportWithRetry();
      debugPrint('[session] opened, running handshake…');
      final hs = await _handshakeWithRetry();

      final typeMatch = hs.deviceType == device.entry.deviceType;
      final idMatch = hs.deviceId == device.entry.devId;
      debugPrint('[session] verify: reported type=${hs.deviceType?.name ?? 'unknown'} '
          '(match=$typeMatch), reported id="${hs.deviceId}" (match=$idMatch)');

      if (typeMatch && idMatch) {
        debugPrint('[session] VERIFIED');
        _listenUnsolicited();
        _controller.add(DeviceSessionState.verified(name, mode));
        return true;
      }
      debugPrint('[session] REJECTED — closing');
      // why: a throwing close() here would fall into the catch below and
      // downgrade this to error, losing the "wrong device" signal.
      await _safeClose();
      _controller.add(DeviceSessionState.rejected(name, mode));
      return false;
    } catch (e) {
      debugPrint('[session] ERROR: $e');
      await _safeClose();
      _controller.add(DeviceSessionState.error(name, mode, e.toString()));
      return false;
    }
  }

  /// Opens L6 transport with [maxOpenAttempts] and [openRetryDelay].
  Future<void> _openTransportWithRetry() async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxOpenAttempts; attempt++) {
      try {
        debugPrint(
          '[session] opening device (attempt $attempt/$maxOpenAttempts)…',
        );
        await _session.open();
        return;
      } catch (e) {
        lastError = e;
        debugPrint(
          '[session] open failed (attempt $attempt/$maxOpenAttempts): $e',
        );
        await _safeClose();
        if (attempt < maxOpenAttempts) {
          await Future<void>.delayed(openRetryDelay);
        }
      }
    }
    throw lastError ??
        StateError('open failed after $maxOpenAttempts attempts');
  }

  /// A1 handshake via L5 with [maxHandshakeAttempts] and [handshakeRetryDelay].
  /// Retries only on throw (timeout / I/O). Catalog mismatch is not retried.
  Future<DeviceHandshake> _handshakeWithRetry() async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxHandshakeAttempts; attempt++) {
      try {
        debugPrint(
          '[session] handshake (attempt $attempt/$maxHandshakeAttempts)…',
        );
        return await _protocol.handshake(_session);
      } catch (e) {
        lastError = e;
        debugPrint(
          '[session] handshake failed (attempt $attempt/$maxHandshakeAttempts): $e',
        );
        if (attempt < maxHandshakeAttempts) {
          await Future<void>.delayed(handshakeRetryDelay);
        }
      }
    }
    throw lastError ??
        StateError('handshake failed after $maxHandshakeAttempts attempts');
  }

  void _listenUnsolicited() {
    _unsolicitedSub?.cancel();
    _unsolicitedSub = _session.unsolicitedReports.listen((raw) {
      debugPrint('[session] unsolicited ${_hex(raw)} (${raw.length}B)');
      final battery = _osd.parseBattery(raw);
      if (battery == null) return;
      debugPrint('[session] OSD battery: ${battery.percent}% '
          'charging=${battery.isCharging} raw=${_hex(raw)}');
      if (!_batteryPushes.isClosed) {
        _batteryPushes.add(battery);
      }
    });
  }

  String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

  Future<void> dispose() async {
    await _unsolicitedSub?.cancel();
    _unsolicitedSub = null;
    await _safeClose();
    await _batteryPushes.close();
    await _controller.close();
  }

  Future<void> _safeClose() async {
    try {
      await _session.close();
    } catch (_) {}
  }
}
