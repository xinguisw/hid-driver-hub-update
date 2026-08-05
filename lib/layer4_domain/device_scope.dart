import 'dart:async';
import 'dart:convert';

import 'package:driver_hub/layer1_discovery/device_scanner.dart';
import 'package:driver_hub/layer1_discovery/device_session.dart';
import 'package:driver_hub/layer1_discovery/device_watcher.dart';
import 'package:driver_hub/layer1_discovery/discovered_device.dart';
import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_bloc.dart';
import 'package:driver_hub/layer4_domain/models/button_mapping_slot.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer4_domain/settings_onboard_query.dart';
import 'package:driver_hub/layer5_codec/codecs/translation_codec.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:driver_hub/layer6_transport/hid_session.dart';
import 'package:driver_hub/layer6_transport/local_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hid_tool/hid_tool.dart';

/// L4 domain scope: owns [DiscoveredCardState] cards and settings load entry.
///
/// Uses L1 ([DeviceScanner], [DeviceWatcher], [DeviceSession]) for lifecycle
/// and L4 [queryOnboardConfig] for settings hydrate. L3 reads [cards] / [busy]
/// and calls [addDevice] / [loadOnboardSettings] only — never sessions or L5.
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

  /// Live sessions for OSD (and optional A4 poll if re-enabled), keyed by path.
  final _sessions = <String, DeviceSession>{};

  /// OSD battery subscriptions per device path.
  final _batterySubs = <String, StreamSubscription<BatteryResult>>{};

  /// Last hydrated settings per device path, for the life of the connection.
  final _settings = <String, DeviceSettingsState>{};

  // --- Polling for battery and charging (DISABLED) ---
  // Manager decision: no A4 poll. Battery/charging stay real-time via OSD push
  // (device sends report 9 opcode 2; we listen). Re-enable the block below if
  // a product later needs host-driven refresh when OSD is unavailable.
  //
  // Timer? _batteryPollTimer;
  // static const _batteryPollInterval = Duration(minutes: 5);

  /// Published card list. The UI listens to rebuild on add/remove.
  final cards = ValueNotifier<List<DiscoveredCardState>>(const []);

  /// Whether a scan/add is in flight.
  final busy = ValueNotifier<bool>(false);

  /// Bumped when held settings change (caps-first or final pack).
  ///
  /// why: L3 repaints from [settingsFor] without waiting on the final Future.
  final settingsVersion = ValueNotifier<int>(0);

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
    // Live updates after connect: OSD push only (no A4 poll).
    // Onboard config GETs (B2/C2/…) only when user opens settings (card tap).
    _upsert(session, battery, firmware);
    _startLiveBattery(session);
  }

  /// Whether this card still has a live session (for L3 disconnect / load guards).
  bool isCardConnected(DiscoveredCardState card) {
    final session = _sessionForCard(card);
    return session != null && session.isAlive;
  }

  /// Latest card snapshot from [cards], or [snap] if not found.
  DiscoveredCardState resolveCard(DiscoveredCardState snap) {
    final list = cards.value;
    for (final c in list) {
      if (identical(c.physicalHandle, snap.physicalHandle) ||
          c.physicalHandle == snap.physicalHandle) {
        return c;
      }
    }
    for (final c in list) {
      if (c.devId == snap.devId && c.connectionMode == snap.connectionMode) {
        return c;
      }
    }
    return snap;
  }

  /// Settings hydrated earlier for [card], or null if none held yet.
  ///
  /// why: lets L3 paint known values at once while a fresh read runs behind.
  DeviceSettingsState? settingsFor(DiscoveredCardState card) {
    final path = _pathForCard(card);
    return path == null ? null : _settings[path];
  }

  /// L4 entry: hydrate settings for [card] (session stays inside domain).
  ///
  /// Caps-first partials are written into [_settings] and bump
  /// [settingsVersion] before the final packed result returns.
  Future<DeviceSettingsState> loadOnboardSettings(DiscoveredCardState card) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      return DeviceSettingsState(
        devId: card.devId,
        displayName: card.displayName,
        connectionMode: card.connectionMode,
        loading: false,
        error: 'no session',
      );
    }
    final path = _pathForCard(card);
    final packed = await queryOnboardConfig(
      session,
      card,
      onPartial: (partial) {
        if (path == null) return;
        _settings[path] = partial;
        settingsVersion.value++;
      },
    );
    // why: a failed read must not become the value a later entry paints from.
    if (path != null && packed.error == null) {
      _settings[path] = packed;
      settingsVersion.value++;
    }
    return packed;
  }

  DeviceSettingsBloc createSettingsBloc(
    DiscoveredCardState card, {
    SaveCompletedCallback? onSaveCompleted,
  }) {
    const translate = TranslationCodec();
    return DeviceSettingsBloc(
      commitButtonMapping: (slots) => commitButtonMapping(card, slots),
      commitReportRate: (hz) => commitReportRate(card, hz),
      commitDpiLevel: (level) => commitDpiLevel(card, level),
      commitSensorTuning: (ripple, snap) =>
          commitSensorTuning(card, ripple, snap),
      commitAngleTune: (wireValue) => commitAngleTune(card, wireValue),
      commitLod: (wire) => commitLod(card, wire),
      commitPerformance: (wire) => commitPerformance(card, wire),
      actionLabelOf: (action, p1, p2, p3) => translate.buttonActionToLabel(
        action: action,
        param1: p1,
        param2: p2,
        param3: p3,
      ),
      buttonIdLabelOf: translate.buttonIdToLabel,
      // why: caps load during loadOnboardSettings, after this bloc is built.
      capabilitiesLookup: () => DeviceCapabilityStore.forDevice(card.devId),
      onSaveCompleted: onSaveCompleted,
    );
  }

  Future<void> commitButtonMapping(
    DiscoveredCardState card,
    List<ButtonMappingSlot> slots,
  ) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitButtonMapping: no session');
    }
    final entries = [
      for (final s in slots)
        ButtonMappingEntry(
          action: s.action,
          param1: s.param1,
          param2: s.param2,
          param3: s.param3,
        ),
    ];
    await session.setButtonMapping(entries);
  }

  Future<void> commitReportRate(
    DiscoveredCardState card,
    int reportRateHz,
  ) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitReportRate: no session');
    }

    // Convert Hz to wire value
    const translate = TranslationCodec();
    final wireValue = translate.reportRateHzToWire(reportRateHz);
    if (wireValue == null) {
      throw StateError('Unknown report rate Hz: $reportRateHz');
    }

    // Read current 3-byte block from device
    final currentBlock = await session.queryReportRateDpiInfo();
    if (currentBlock == null) {
      throw StateError('Failed to read current report rate block');
    }

    // Build new block: [newReportRateWire, currentDpiLevel, currentDpiActive]
    final dataBlock = Uint8List(3);
    dataBlock[0] = wireValue;
    dataBlock[1] = currentBlock.dpiCurrentLevel;
    dataBlock[2] = currentBlock.dpiActiveLevel;

    await session.setReportRate(dataBlock);
  }

  Future<void> commitDpiLevel(
    DiscoveredCardState card,
    int dpiLevel,
  ) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitDpiLevel: no session');
    }

    // Convert 1-based display level to 0-based wire value
    const translate = TranslationCodec();
    final wireValue = translate.dpiCurrentLevelDisplayToWire(dpiLevel);
    if (wireValue == null) {
      throw StateError('Invalid DPI level: $dpiLevel');
    }

    // Read current 3-byte block from device
    final currentBlock = await session.queryReportRateDpiInfo();
    if (currentBlock == null) {
      throw StateError('Failed to read current DPI block');
    }

    // Build new block: [currentReportRateWire, newDpiLevelWire, currentDpiActive]
    final dataBlock = Uint8List(3);
    dataBlock[0] = currentBlock.reportRate;
    dataBlock[1] = wireValue;
    dataBlock[2] = currentBlock.dpiActiveLevel;

    await session.setReportRate(dataBlock);
  }

  /// Commits ripple control + angle snap into the 14-byte 0xD4 block.
  ///
  /// why: sensor tuning shares one block with LOD/debounce/sleep/wheel, so the
  /// current block is read first and only the two tuning bytes are replaced.
  Future<void> commitSensorTuning(
    DiscoveredCardState card,
    bool rippleControl,
    bool angleSnap,
  ) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitSensorTuning: no session');
    }

    final current = await session.querySensorOther();
    if (current == null) {
      throw StateError('Failed to read current sensor/other block');
    }

    // why: L5 owns wire encoding; these two bytes are tri-state (0xFF/0x0F),
    // so a raw 1/0 would read back as neither on nor off.
    const translate = TranslationCodec();
    final dataBlock = Uint8List.fromList(current.data);
    dataBlock[0] = translate.triStateBoolToWire(rippleControl);
    dataBlock[1] = translate.triStateBoolToWire(angleSnap);

    await session.setSensorOther(dataBlock);
  }

  /// Commits angle tune value into the 14-byte 0xD4 block.
  ///
  /// why: angle tune shares one block with ripple/angle snap/LOD/debounce/sleep/wheel,
  /// so the current block is read first and only the angle tune byte is replaced.
  Future<void> commitAngleTune(
    DiscoveredCardState card,
    int wireValue,
  ) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitAngleTune: no session');
    }

    final current = await session.querySensorOther();
    if (current == null) {
      throw StateError('Failed to read current sensor/other block');
    }

    // why: angle tune is at byte index 3 in the 0xD4 block, per the 14-byte
    // layout [rippleControl(0), angleSnap(1), lod(2), angleTune(3), ...].
    final dataBlock = Uint8List.fromList(current.data);
    dataBlock[3] = wireValue;

    await session.setSensorOther(dataBlock);
  }

  /// Commits the LOD value into the 14-byte 0xD4 block.
  ///
  /// why: LOD shares one block with ripple/angle snap/angle tune/debounce/sleep/wheel,
  /// so the current block is read first and only the LOD byte is replaced.
  Future<void> commitLod(
    DiscoveredCardState card,
    int wire,
  ) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitLod: no session');
    }

    final current = await session.querySensorOther();
    if (current == null) {
      throw StateError('Failed to read current sensor/other block');
    }

    // why: LOD is at byte index 2 in the 0xD4 block, per the 14-byte layout
    // [rippleControl(0), angleSnap(1), lod(2), angleTune(3), ...].
    final dataBlock = Uint8List.fromList(current.data);
    dataBlock[2] = wire;

    await session.setSensorOther(dataBlock);
  }

  /// Commits the performance mode into the 14-byte 0xD4 block.
  ///
  /// TODO(mock): real performance semantics pending; this just writes the
  /// selected wire value into the performance byte.
  Future<void> commitPerformance(
    DiscoveredCardState card,
    int wire,
  ) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitPerformance: no session');
    }

    final current = await session.querySensorOther();
    if (current == null) {
      throw StateError('Failed to read current sensor/other block');
    }

    // why: performance is at byte index 4 in the 0xD4 block, per the 14-byte
    // layout [rippleControl(0), angleSnap(1), lod(2), angleTune(3),
    // performance(4), ...].
    final dataBlock = Uint8List.fromList(current.data);
    dataBlock[4] = wire;

    await session.setSensorOther(dataBlock);
  }

  /// Persist BLoC-synced settings after successful Save (cache for re-entry).
  void putSettings(DiscoveredCardState card, DeviceSettingsState settings) {
    final path = _pathForCard(card);
    if (path == null) return;
    _settings[path] = settings;
    settingsVersion.value++;
  }

  DeviceSession? _sessionForCard(DiscoveredCardState card) {
    final path = _pathForCard(card);
    return path == null ? null : _sessions[path];
  }

  String? _pathForCard(DiscoveredCardState card) {
    final handle = card.physicalHandle;
    return handle is HidDevice ? handle.path : null;
  }

  /// Subscribe to device OSD battery/charging pushes (real-time from device).
  void _startLiveBattery(DeviceSession session) {
    final path = session.device.hidDevice.path;
    _sessions[path] = session;
    _bindBatteryPush(session);
    // Polling for battery and charging — disabled (OSD is real-time source).
    // _ensureBatteryPollTimer();
  }

  /// Live OSD battery (report 9 opcode 2) → patch existing card.
  void _bindBatteryPush(DeviceSession session) {
    final path = session.device.hidDevice.path;
    _batterySubs.remove(path)?.cancel();
    _batterySubs[path] = session.batteryPushes.listen((b) {
      _patchBattery(path, b, source: 'osd');
    });
  }

  // --- Polling for battery and charging (DISABLED) ---
  // Host-driven A4 refresh on a timer. Not used while OSD push covers live
  // battery/charging. Uncomment + restore fields above if polling is needed.
  //
  // void _ensureBatteryPollTimer() {
  //   if (_batteryPollTimer != null) return;
  //   _batteryPollTimer = Timer.periodic(_batteryPollInterval, (_) {
  //     unawaited(_pollAllBatteries());
  //   });
  //   debugPrint(
  //       '[scope] battery poll every ${_batteryPollInterval.inSeconds}s');
  // }
  //
  // void _stopBatteryPollTimerIfIdle() {
  //   if (_sessions.isNotEmpty) return;
  //   _batteryPollTimer?.cancel();
  //   _batteryPollTimer = null;
  // }
  //
  // Future<void> _pollAllBatteries() async {
  //   final snapshot = Map<String, DeviceSession>.from(_sessions);
  //   for (final entry in snapshot.entries) {
  //     final path = entry.key;
  //     final session = entry.value;
  //     if (!session.isAlive) continue;
  //     debugPrint('[scope] poll A4 ${session.device.entry.model}');
  //     final battery = await _queryBattery(session);
  //     if (battery == null) continue;
  //     if (!session.isAlive || !_cards.containsKey(path)) continue;
  //     _patchBattery(path, battery, source: 'poll');
  //   }
  // }

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
          'mouse=${result.mouseVersionLabel} '
          'dongle=${result.dongleVersionLabel}');
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
    _settings.remove(path);
    // Polling for battery and charging — disabled.
    // _stopBatteryPollTimerIfIdle();
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
      // USB and receiver both show mouse FW (not dongle).
      firmwareVersion: _firmwareLabel(firmware),
      batteryPercentage: battery?.percent ?? -1,
      isCharging: battery?.isCharging ?? false,
      physicalHandle: session.device.hidDevice,
      imageSmall: entry.image.small,
      imageLarge: entry.image.large,
    );
  }

  /// Mouse firmware for card display on USB and 2.4G. Empty when query failed.
  String _firmwareLabel(FirmwareResult? firmware) {
    if (firmware == null) return '';
    return firmware.mouseVersionLabel;
  }

  Future<void> dispose() async {
    // Polling for battery and charging — disabled.
    // _batteryPollTimer?.cancel();
    // _batteryPollTimer = null;
    for (final sub in _batterySubs.values) {
      await sub.cancel();
    }
    _batterySubs.clear();
    _sessions.clear();
    await _watcher.stop();
    cards.dispose();
    busy.dispose();
    settingsVersion.dispose();
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
