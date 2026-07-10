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
        _publishWithBattery(session); // verified by watcher → query A4 → show
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
    await _publishWithBattery(session);
  }

  /// Queries battery (A4) before publishing — card shows once, populated.
  /// Called from both [_startAndRegister] (launch/scan) and watcher
  /// [onConnect] (hot-plug, session already verified).
  Future<void> _publishWithBattery(DeviceSession session) async {
    final battery = await _queryBattery(session);
    _upsert(session, battery);
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

  /// Publishes the card for [session] only when [battery] is available.
  /// If battery is null (query failed), the card is NOT shown — per the
  /// contract that a card renders only with battery+charging info present.
  void _upsert(DeviceSession session, [BatteryResult? battery]) {
    final path = session.device.hidDevice.path;
    if (battery == null) {
      debugPrint('[scope] no battery for ${session.device.entry.model} '
          '— card not shown');
      return;
    }
    _cards[path] = _cardStateFor(session, battery);
    cards.value = List.unmodifiable(_cards.values);
  }

  void _remove(String path) {
    _cards.remove(path);
    cards.value = List.unmodifiable(_cards.values);
  }

  /// L1 → L3 bridge: builds the card state from a verified session's catalog
  /// context plus the A4 battery result. Called only with a non-null battery
  /// (the card is suppressed until then), so fields are real, not sentinels.
  /// Firmware is still a sentinel (opcode A8, not yet built).
  DiscoveredCardState _cardStateFor(DeviceSession session, BatteryResult battery) {
    final entry = session.device.entry;
    return DiscoveredCardState(
      devId: entry.devId,
      displayName: entry.model,
      connectionMode: session.device.mode.mode,
      firmwareVersion: '',
      batteryPercentage: battery.percent,
      isCharging: battery.isCharging,
      physicalHandle: session.device.hidDevice,
      imageSmall: entry.image.small,
      imageLarge: entry.image.large,
    );
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
