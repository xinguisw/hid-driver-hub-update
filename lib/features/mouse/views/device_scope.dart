import 'dart:async';
import 'dart:convert';

import 'package:driver_hub/core/device/device_scanner.dart';
import 'package:driver_hub/core/device/discovered_device.dart';
import 'package:driver_hub/core/device/hid_session.dart';
import 'package:driver_hub/core/hid/local_storage.dart';
import 'package:driver_hub/features/mouse/models/discovered_card_state.dart';
import 'package:driver_hub/features/mouse/protocol/device_protocol.dart';
import 'package:driver_hub/features/mouse/repositories/device_session.dart';
import 'package:driver_hub/features/mouse/repositories/device_watcher.dart';
import 'package:flutter/foundation.dart';

/// Owns the device lifecycle (L1) and exposes card state to the UI (L3).
///
/// This is the seam between L1 (discovery + session lifecycle) and L3
/// (presentation): it holds the [DeviceWatcher], aggregates verified sessions
/// into [DiscoveredCardState]s, and publishes them via [cards]. The UI never
/// touches the scanner, session, or HID — it reads [cards] and calls
/// [addDevice].
///
/// One entry per verified device, keyed by device path → multi-device.
class DeviceScope {
  DeviceScope({
    DeviceScanner? scanner,
  }) : _scanner = scanner ?? DeviceScanner() {
    _watcher = DeviceWatcher(
      scanner: _scanner,
      protocolFactory: () => const MouseProtocol(),
      sessionFactory: (d) => HidSession(d.hidDevice),
      sessionCtor: DeviceSession.new,
    );
  }

  final DeviceScanner _scanner;
  late final DeviceWatcher _watcher;

  /// Verified devices as card states, keyed by device path.
  final _cards = <String, DiscoveredCardState>{};

  /// Published card list. The UI listens to rebuild on add/remove.
  final cards = ValueNotifier<List<DiscoveredCardState>>(const []);

  /// Whether a scan/add is in flight.
  final busy = ValueNotifier<bool>(false);

  void start() {
    _watcher.start(
      onConnect: (session) {
        _saveLastDevice(session.device);
        _publishCard(session); // verified by watcher → query A4/A8 → show
      },
      onDisconnect: (path, vid, pid) => _remove(path),
    );
    probeExisting();
  }

  /// Devices present at launch; the watcher only fires on a NEW plug.
  Future<void> probeExisting() async {
    busy.value = true;
    try {
      final devices = await _scanner.discoverAuthorized();
      for (final d in devices) {
        await _startAndRegister(d);
      }
    } catch (_) {
    } finally {
      busy.value = false;
    }
  }

  /// Web: first-ever connect needs a user gesture (browser rule). Safe to call
  /// even with devices already connected — used to add a second device.
  Future<void> addDevice() async {
    if (busy.value) return;
    busy.value = true;
    try {
      final devices = await _scanner.discover();
      for (final d in devices) {
        await _startAndRegister(d);
      }
    } catch (_) {
    } finally {
      busy.value = false;
    }
  }

  Future<void> _startAndRegister(DiscoveredDevice d) async {
    final session = DeviceSession(
      device: d,
      session: HidSession(d.hidDevice),
      protocol: const MouseProtocol(),
    );
    final verified = await session.start();
    if (!verified) return;
    _watcher.register(session);
    await _publishCard(session);
  }

  /// Queries battery (A4) and firmware (A8) before publishing — card shows
  /// once, populated. Called from both [_startAndRegister] (launch/scan) and
  /// watcher [onConnect] (hot-plug, session already verified).
  Future<void> _publishCard(DeviceSession session) async {
    final battery = await _queryBattery(session);
    final firmware = await _queryFirmware(session);
    _upsert(session, battery, firmware);
  }

  /// Queries battery+charging via A4. Returns null on failure so the caller
  /// can fall back to sentinels rather than hiding a verified device.
  Future<BatteryResult?> _queryBattery(DeviceSession session) async {
    try {
      final result = await session.queryBattery();
      debugPrint('[scope] battery for ${session.device.entry.model}: '
          '${result.percent}% charging=${result.isCharging}');
      return result;
    } catch (e) {
      debugPrint('[scope] battery query failed for '
          '${session.device.entry.model}: $e');
      return null;
    }
  }

  /// Queries mouse/dongle firmware via A8. Returns null on failure — firmware
  /// is best-effort and does not gate the card (battery does).
  Future<FirmwareResult?> _queryFirmware(DeviceSession session) async {
    try {
      final result = await session.queryFirmware();
      debugPrint('[scope] firmware for ${session.device.entry.model}: '
          'mouse=${result.mouseVersion.join('.')} '
          'dongle=${result.dongleVersion.join('.')}');
      return result;
    } catch (e) {
      debugPrint('[scope] firmware query failed for '
          '${session.device.entry.model}: $e');
      return null;
    }
  }

  /// Publishes the card for [session] only when [battery] is available.
  /// [firmware] is best-effort — null (query failed) leaves firmware as a
  /// sentinel ("—") but does not suppress the card; battery is the gate.
  void _upsert(DeviceSession session, BatteryResult? battery,
      [FirmwareResult? firmware]) {
    final path = session.device.hidDevice.path;
    if (battery == null) {
      debugPrint('[scope] no battery for ${session.device.entry.model} '
          '— card not shown');
      return;
    }
    _cards[path] = _cardStateFor(session, battery, firmware);
    cards.value = List.unmodifiable(_cards.values);
  }

  void _remove(String path) {
    _cards.remove(path);
    cards.value = List.unmodifiable(_cards.values);
  }

  /// L1 → L3 bridge: builds the card state from a verified session's catalog
  /// context plus the A4 battery and A8 firmware results. Battery gates the
  /// card (caller ensures non-null); firmware may be null (query failed).
  DiscoveredCardState _cardStateFor(DeviceSession session, BatteryResult battery,
      [FirmwareResult? firmware]) {
    final entry = session.device.entry;
    return DiscoveredCardState(
      devId: entry.devId,
      displayName: entry.model,
      connectionMode: session.device.mode.mode,
      // Show the firmware of the device on the wire: USB → mouse FW,
      // 2.4G → dongle FW (the receiver is what we're talking to).
      firmwareVersion: _firmwareLabel(session.device.mode.mode, firmware),
      batteryPercentage: battery.percent,
      isCharging: battery.isCharging,
      physicalHandle: session.device.hidDevice,
      imageSmall: entry.image.small,
      imageLarge: entry.image.large,
    );
  }

  /// Picks the firmware label for the active connection mode.
  /// USB (0) → mouse FW; 2.4G (1) → dongle FW. Empty when query failed.
  String _firmwareLabel(int mode, FirmwareResult? firmware) {
    if (firmware == null) return '';
    return mode == 0 ? firmware.mouseVersionLabel : firmware.dongleVersionLabel;
  }

  Future<void> dispose() async {
    await _watcher.stop();
    cards.dispose();
    busy.dispose();
  }
}

// --- last-device hint (web localStorage; no-op on non-web) ---

const _lastHidKey = 'driver_hub.lastHid';

void _saveLastDevice(DiscoveredDevice d) {
  if (!kIsWeb) return;
  try {
    final payload = jsonEncode({
      'vendorId': d.mode.vid,
      'productId': d.mode.pid,
      'productName': d.entry.model,
    });
    writeLocalStorage(_lastHidKey, payload);
  } catch (_) {}
}
