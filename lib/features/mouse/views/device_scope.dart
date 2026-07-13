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

  /// Live sessions for poll + OSD, keyed by device path.
  final _sessions = <String, DeviceSession>{};

  /// OSD battery subscriptions per device path.
  final _batterySubs = <String, StreamSubscription<BatteryResult>>{};

  /// Shared A4 poll timer (desktop + web). One timer for all cards.
  Timer? _batteryPollTimer;

  /// How often to re-query battery via A4 (backup if OSD is quiet).
  static const _batteryPollInterval = Duration(seconds: 300);// 5min

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

  /// Queries battery (A4) and firmware (A8) before publishing. Called from
  /// [_startAndRegister] (launch/scan) and watcher [onConnect] (hot-plug).
  ///
  /// Guards on [DeviceSession.isAlive] after the awaits: if the device
  /// disconnected mid-query the watcher already removed its card, so don't
  /// re-add a stale one.
  Future<void> _publishCard(DeviceSession session) async {
    final battery = await _queryBattery(session);
    final firmware = await _queryFirmware(session);
    if (!session.isAlive) {
      debugPrint('[scope] ${session.device.entry.model} gone mid-query, '
          'skipping publish');
      return;
    }
    // Soft battery: always show card after verify; unknown battery is "—".
    // Still start OSD/poll so a later value can fill in.
    _upsert(session, battery, firmware);
    _startLiveBattery(session);
  }

  /// OSD push + A4 poll for this device (same path on desktop and web).
  void _startLiveBattery(DeviceSession session) {
    final path = session.device.hidDevice.path;
    _sessions[path] = session;
    _bindBatteryPush(session);
    _ensureBatteryPollTimer();
  }

  /// Live OSD battery (report 9 opcode 2) → patch existing card.
  void _bindBatteryPush(DeviceSession session) {
    final path = session.device.hidDevice.path;
    _batterySubs.remove(path)?.cancel();
    _batterySubs[path] = session.batteryPushes.listen((b) {
      _patchBattery(path, b, source: 'osd');
    });
  }

  void _ensureBatteryPollTimer() {
    if (_batteryPollTimer != null) return;
    _batteryPollTimer = Timer.periodic(_batteryPollInterval, (_) {
      unawaited(_pollAllBatteries());
    });
    debugPrint('[scope] battery poll every ${_batteryPollInterval.inSeconds}s');
  }

  void _stopBatteryPollTimerIfIdle() {
    if (_sessions.isNotEmpty) return;
    _batteryPollTimer?.cancel();
    _batteryPollTimer = null;
  }

  /// A4 poll for every live session. Soft-fail: keep last card values on error.
  Future<void> _pollAllBatteries() async {
    final snapshot = Map<String, DeviceSession>.from(_sessions);
    for (final entry in snapshot.entries) {
      final path = entry.key;
      final session = entry.value;
      if (!session.isAlive) continue;
      debugPrint('[scope] poll A4 ${session.device.entry.model}');
      final battery = await _queryBattery(session);
      if (battery == null) continue; // keep last shown values
      if (!session.isAlive || !_cards.containsKey(path)) continue;
      _patchBattery(path, battery, source: 'poll');
    }
  }

  void _patchBattery(String path, BatteryResult battery, {required String source}) {
    final prev = _cards[path];
    if (prev == null) return;
    debugPrint('[scope] live battery ($source) ${prev.displayName}: '
        '${battery.percent}% charging=${battery.isCharging}');
    _cards[path] = prev.copyWith(
      batteryPercentage: battery.percent,
      isCharging: battery.isCharging,
    );
    cards.value = List.unmodifiable(_cards.values);
  }

  /// Queries battery+charging via A4. Returns null on failure (device gone,
  /// query threw) so the caller can fall back to sentinels rather than hiding
  /// a verified device.
  Future<BatteryResult?> _queryBattery(DeviceSession session) async {
    try {
      final result = await session.queryBattery();
      if (result == null) {
        debugPrint('[scope] battery skipped: ${session.device.entry.model} '
            'no longer alive');
        return null;
      }
      debugPrint('[scope] battery for ${session.device.entry.model}: '
          '${result.percent}% charging=${result.isCharging}');
      return result;
    } catch (e) {
      debugPrint('[scope] battery query failed for '
          '${session.device.entry.model}: $e');
      return null;
    }
  }

  /// Queries mouse/dongle firmware via A8. Returns null on failure (best-effort).
  Future<FirmwareResult?> _queryFirmware(DeviceSession session) async {
    try {
      final result = await session.queryFirmware();
      if (result == null) {
        debugPrint('[scope] firmware skipped: ${session.device.entry.model} '
            'no longer alive');
        return null;
      }
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

  /// Publishes a card for a verified [session].
  /// Battery/firmware null → sentinels ("—" on the card); session stays usable.
  void _upsert(DeviceSession session, BatteryResult? battery,
      [FirmwareResult? firmware]) {
    final path = session.device.hidDevice.path;
    if (battery == null) {
      debugPrint('[scope] no battery yet for ${session.device.entry.model} '
          '— card shown with Battery —');
    }
    _cards[path] = _cardStateFor(session, battery, firmware);
    cards.value = List.unmodifiable(_cards.values);
  }

  void _remove(String path) {
    _batterySubs.remove(path)?.cancel();
    _sessions.remove(path);
    _stopBatteryPollTimerIfIdle();
    _cards.remove(path);
    cards.value = List.unmodifiable(_cards.values);
  }

  /// L1 → L3 bridge: catalog + optional A4/A8. Unknown battery → -1 ("—").
  DiscoveredCardState _cardStateFor(DeviceSession session, BatteryResult? battery,
      [FirmwareResult? firmware]) {
    final entry = session.device.entry;
    return DiscoveredCardState(
      devId: entry.devId,
      displayName: entry.model,
      connectionMode: session.device.mode.mode,
      // USB → mouse FW; 2.4G → dongle FW.
      firmwareVersion: _firmwareLabel(session.device.mode.mode, firmware),
      batteryPercentage: battery?.percent ?? -1,
      isCharging: battery?.isCharging ?? false,
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
    _batteryPollTimer?.cancel();
    _batteryPollTimer = null;
    for (final sub in _batterySubs.values) {
      await sub.cancel();
    }
    _batterySubs.clear();
    _sessions.clear();
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
