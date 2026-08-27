import 'dart:async';

import 'package:driver_hub/layer1_discovery/device_runtime.dart';
import 'package:driver_hub/layer1_discovery/device_settings_gateway.dart';
import 'package:driver_hub/layer1_discovery/discovered_device.dart';
import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer4_domain/app_settings_repository.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_bloc.dart';
import 'package:driver_hub/layer4_domain/device_repository.dart';
import 'package:driver_hub/layer5_codec/button_mapping_slot.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer4_domain/models/macro.dart';
import 'package:driver_hub/layer4_domain/models/osd_event.dart';
import 'package:driver_hub/layer4_domain/macro_repository.dart';
import 'package:driver_hub/layer4_domain/low_battery_alert_policy.dart';
import 'package:driver_hub/layer4_domain/settings_onboard_query.dart';
import 'package:driver_hub/layer5_codec/codecs/osd_codec.dart';
import 'package:driver_hub/layer5_codec/codecs/translation_codec.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:driver_hub/layer5_codec/macro_codec.dart';
import 'package:flutter/foundation.dart';

/// L4 domain scope: owns [DiscoveredCardState] cards and settings load entry.
///
/// Uses the L1 [DeviceRuntime] lifecycle port and L4 [queryOnboardConfig] for
/// settings hydrate. L3 reads [cards] / [busy]
/// and calls [addDevice] / [loadOnboardSettings] only — never sessions or L5.
///
/// One entry per verified device, keyed by device path → multi-device.
class DeviceScope {
  factory DeviceScope({
    required DeviceRuntime runtime,
    required MacroRepository macroRepository,
    required AppSettingsRepository appSettingsRepository,
  }) => DeviceScope._(runtime, macroRepository, appSettingsRepository);

  /// Named generative entry point for tests that need to override the domain
  /// boundary while still supplying the real runtime dependencies.
  DeviceScope.forTesting({
    required DeviceRuntime runtime,
    required MacroRepository macroRepository,
    required AppSettingsRepository appSettingsRepository,
  }) : this._(runtime, macroRepository, appSettingsRepository);

  DeviceScope._(
    this._runtime,
    this._macroRepository,
    this._appSettingsRepository,
  );

  final DeviceRuntime _runtime;
  final MacroRepository _macroRepository;
  final AppSettingsRepository _appSettingsRepository;

  /// Verified devices as card states, keyed by device path.
  final _cards = <String, DiscoveredCardState>{};

  /// Live device gateways for OSD (and optional A4 poll if re-enabled), keyed
  /// by path.
  final _sessions = <String, DeviceSettingsGateway>{};

  /// OSD battery subscriptions per device path.
  final _batterySubs = <String, StreamSubscription<BatteryResult>>{};

  /// Device status subscriptions per device path.
  final _statusSubs = <String, StreamSubscription<DeviceStatusResult>>{};

  /// In-flight wake re-query locks per device path to prevent concurrent bus flooding.
  final _reQueryingPaths = <String>{};

  /// OSD performance subscriptions per device path.
  final _performanceSubs = <String, StreamSubscription<OsdPerformanceResult>>{};

  /// Semantic OSD events for the presentation layer.
  final _osdEvents = StreamController<OsdPerformanceEvent>.broadcast();

  /// Semantic low-battery OSD events for the presentation layer.
  final _batteryLowOsdEvents = StreamController<OsdBatteryLowEvent>.broadcast();

  final _lowBatteryAlerts = LowBatteryAlertPolicy();

  static const defaultLowBatteryThreshold = 20;
  static const lowBatteryThresholdOptions = <int>{10, 20, 30, 40};

  /// Global threshold loaded from L6 before device discovery starts.
  final batteryLowThreshold = ValueNotifier<int>(defaultLowBatteryThreshold);

  bool _started = false;

  /// Last hydrated settings per device path, for the life of the connection.
  final _settings = <String, DeviceSettingsState>{};

  /// Macro registry cached per catalog device id for the current app session.
  /// The registry is the app-side source of truth because the firmware defines
  /// no macro GET/read-back operation.
  final _macros = <String, List<MacroDefinition>>{};

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

  /// Background performance events with raw HID details removed.
  Stream<OsdPerformanceEvent> get osdEvents => _osdEvents.stream;

  Stream<OsdBatteryLowEvent> get batteryLowOsdEvents =>
      _batteryLowOsdEvents.stream;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _loadLowBatteryThreshold();
    _runtime.startWatching(
      onConnect: (session) {
        _publishCard(session); // verified by watcher → query A4/A8 → show
      },
      onDisconnect: (path, vid, pid) => _remove(path),
    );
    await probeExisting();
  }

  Future<void> setLowBatteryThreshold(int threshold) async {
    if (!lowBatteryThresholdOptions.contains(threshold)) {
      throw ArgumentError.value(
        threshold,
        'threshold',
        'must be one of $lowBatteryThresholdOptions',
      );
    }
    if (batteryLowThreshold.value == threshold) return;

    batteryLowThreshold.value = threshold;
    _reevaluateKnownBatteryLevels();
    try {
      await _appSettingsRepository.saveLowBatteryThreshold(threshold);
    } catch (error) {
      debugPrint('[scope] low battery threshold persistence failed: $error');
    }
  }

  Future<void> _loadLowBatteryThreshold() async {
    try {
      final stored = await _appSettingsRepository.loadLowBatteryThreshold();
      if (stored != null && lowBatteryThresholdOptions.contains(stored)) {
        batteryLowThreshold.value = stored;
      }
    } catch (error) {
      debugPrint('[scope] low battery threshold load failed: $error');
    }
  }

  /// Devices present at launch; the watcher only fires on a NEW plug.
  Future<void> probeExisting() async {
    busy.value = true;
    try {
      final devices = await _runtime.discoverAuthorized();
      await Future.wait(devices.map((d) => _startAndRegister(d)));
    } catch (e) {
      debugPrint('[scope] probeExisting error: $e');
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
      final devices = await _runtime.discover();
      await Future.wait(devices.map((d) => _startAndRegister(d)));
    } catch (e) {
      debugPrint('[scope] addDevice error: $e');
    } finally {
      busy.value = false;
    }
  }

  Future<void> _startAndRegister(DiscoveredDevice d) async {
    try {
      final session = await _runtime.openAndRegister(d);
      if (session == null) return;
      await _publishCard(session);
    } catch (e) {
      debugPrint(
        '[scope] failed to start and register device ${d.entry.model}: $e',
      );
    }
  }

  /// Mounts card immediately upon verification, then asynchronously hydrates
  /// battery (A4) and firmware (A8) telemetry. Called from [_startAndRegister]
  /// (launch/scan) and watcher [onConnect] (hot-plug).
  Future<void> _publishCard(DeviceSettingsGateway session) async {
    if (!session.isAlive) {
      debugPrint(
        '[scope] ${session.info.displayName} not alive, skipping publish',
      );
      return;
    }

    // Step 1: Immediately publish card with initial status, battery, and firmware from start()
    final initStatus = session.initialDeviceStatus;
    final initBattery = session.initialBattery;
    final initFirmware = session.initialFirmware;
    _upsert(session, initBattery, initFirmware, initStatus);
    if (initBattery != null) {
      _evaluateLowBattery(session.info.deviceKey, initBattery);
    }
    _startLiveBattery(session);
    _startLiveStatus(session);

    // Step 2: If status indicates asleep, or either battery/firmware missing, query in background.
    if (initBattery == null || initFirmware == null) {
      try {
        final battery = initBattery ?? await _queryBattery(session);
        final firmware = initFirmware ?? await _queryFirmware(session);
        if (!session.isAlive) {
          debugPrint(
            '[scope] ${session.info.displayName} gone mid-query, skipping update',
          );
          return;
        }
        if (battery != null || firmware != null) {
          _upsert(session, battery, firmware);
          if (battery != null) {
            _evaluateLowBattery(session.info.deviceKey, battery);
          }
        }
      } catch (e) {
        debugPrint(
          '[scope] telemetry query failed for ${session.info.displayName}: $e',
        );
      }
    }
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
      if (c.deviceKey.isNotEmpty && c.deviceKey == snap.deviceKey) return c;
    }
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
  Future<DeviceSettingsState> loadOnboardSettings(
    DiscoveredCardState card,
  ) async {
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
      _GatewayDeviceRepository(session, card),
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
    EscalationCallback? onEscalationRequested,
  }) {
    const translate = TranslationCodec();
    return DeviceSettingsBloc(
      commitButtonMapping: (slots) => commitButtonMapping(card, slots),
      commitReportRate: (hz) => commitReportRate(card, hz),
      commitDpiLevel: (level) => commitDpiLevel(card, level),
      commitDpiValues: (values) => commitDpiValues(card, values),
      commitDpiRgb: (colors) => commitDpiRgb(card, colors),
      commitDpiStages: (staged, count) => commitDpiStages(card, staged, count),
      commitDpiConfigurationDefaults: (reportRate, dpiLevel, levels, count) =>
          commitDpiConfigurationDefaults(
            card,
            reportRateHz: reportRate,
            dpiLevel: dpiLevel,
            defaultLevels: levels,
            activeCount: count,
          ),
      commitSensorTuning: (ripple, snap) =>
          commitSensorTuning(card, ripple, snap),
      commitAngleTune: (wireValue) => commitAngleTune(card, true, wireValue),
      commitAngleTuneSettings: (enabled, wireValue) =>
          commitAngleTune(card, enabled, wireValue),
      commitLod: (wire) => commitLod(card, wire),
      commitPerformance: (wire) => commitPerformance(card, wire),
      commitDebounce: (wire) => commitDebounce(card, wire),
      commitSleep: (wire) => commitSleep(card, wire),
      commitWheelInvert: (invert) => commitWheelInvert(card, invert),
      commitParameterSettings: (patch) => commitParameterSettings(card, patch),
      commitRgbBacklight: (values) => commitRgbBacklight(card, values),
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
      onEscalationRequested: onEscalationRequested,
      onPerformanceSettingsSaved: _emitSavedPerformanceOsd,
    );
  }

  /// Load the semantic macro registry for one device from the L6 backend.
  Future<List<MacroDefinition>> loadMacros(DiscoveredCardState card) async {
    final cached = _macros[card.devId];
    if (cached != null) return cached;
    final loaded = await _macroRepository.load(card.devId);
    _macros[card.devId] = List.unmodifiable(loaded);
    return _macros[card.devId]!;
  }

  List<MacroDefinition> macrosFor(DiscoveredCardState card) =>
      List.unmodifiable(_macros[card.devId] ?? const []);

  /// Lowest unused hardware slot, or null when all 16 slots are allocated.
  int? nextMacroSlot(DiscoveredCardState card) {
    final used =
        _macros[card.devId]?.map((m) => m.slot).toSet() ?? const <int>{};
    for (var slot = 1; slot <= MacroDefinition.maxSlots; slot++) {
      if (!used.contains(slot)) return slot;
    }
    return null;
  }

  /// FR-OPS Save: validate, write all three hardware chunks, then persist the
  /// semantic registry only after the device reports final status OK.
  Future<void> saveMacro(
    DiscoveredCardState card,
    MacroDefinition macro,
  ) async {
    final errors = validateMacro(macro);
    if (errors.isNotEmpty) throw FormatException(errors.join('; '));
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('saveMacro: no session');
    }
    await session.setMacro(
      MacroTransferDefinition(
        slot: macro.slot,
        modeWire: macro.mode.wireValue,
        loopTimes: macro.loopTimes,
        actions: [
          for (final action in macro.actions)
            MacroTransferAction(
              keyCode: action.keyCode,
              isBreak: action.isBreak,
              delay: action.delay,
            ),
        ],
      ),
    );
    final current = [...(_macros[card.devId] ?? const <MacroDefinition>[])];
    final index = current.indexWhere((m) => m.slot == macro.slot);
    if (index == -1) {
      current.add(macro);
    } else {
      current[index] = macro;
    }
    current.sort((a, b) => a.slot.compareTo(b.slot));
    await _macroRepository.save(card.devId, current);
    _macros[card.devId] = List.unmodifiable(current);
  }

  /// Delete a macro definition from local persistent storage.
  Future<void> deleteMacro(DiscoveredCardState card, int slot) async {
    debugPrint('[scope] ${card.displayName}: deleting macro slot M$slot');
    final current = [...(_macros[card.devId] ?? const <MacroDefinition>[])];
    current.removeWhere((m) => m.slot == slot);
    await _macroRepository.save(card.devId, current);
    _macros[card.devId] = List.unmodifiable(current);
    debugPrint(
      '[scope] ${card.displayName}: deleted macro slot M$slot from storage successfully',
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

  DeviceSettingsRawBlocks _requireRawBlocks(
    DiscoveredCardState card,
    String operation,
  ) {
    final path = _pathForCard(card);
    final raw = path == null ? null : _settings[path]?.rawBlocks;
    if (raw == null) {
      throw StateError(
        '$operation: raw settings snapshot unavailable; reload settings',
      );
    }
    return raw;
  }

  void _updateRawBlocks(DiscoveredCardState card, DeviceSettingsRawBlocks raw) {
    final path = _pathForCard(card);
    final current = path == null ? null : _settings[path];
    if (path != null && current != null) {
      _settings[path] = current.copyWith(rawBlocks: raw);
    }
  }

  Future<void> _commitSensorOtherPatch(
    DiscoveredCardState card,
    String operation, {
    bool? rippleEnabled,
    bool? angleSnapEnabled,
    bool? angleTuneEnabled,
    int? angleTuneWire,
    int? lodWire,
    int? performanceWire,
    int? debounceWire,
    int? sleepWire,
    bool? wheelInvert,
  }) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('$operation: no session');
    }
    final raw = _requireRawBlocks(card, operation);
    final d4 = raw.sensorOther;
    if (d4 == null || d4.length != 18) {
      throw StateError('$operation: D4 raw block is unavailable');
    }
    final dataBlock = await session.setSensorOtherPatch(
      d4,
      rippleEnabled: rippleEnabled,
      angleSnapEnabled: angleSnapEnabled,
      angleTuneEnabled: angleTuneEnabled,
      angleTuneWire: angleTuneWire,
      lodWire: lodWire,
      performanceWire: performanceWire,
      debounceWire: debounceWire,
      sleepWire: sleepWire,
      wheelInvert: wheelInvert,
    );
    _updateRawBlocks(card, raw.copyWith(sensorOther: dataBlock));
  }

  Future<void> commitReportRate(
    DiscoveredCardState card,
    int reportRateHz,
  ) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitReportRate: no session');
    }

    const translate = TranslationCodec();
    final wireValue = translate.reportRateHzToWire(reportRateHz);
    if (wireValue == null) {
      throw StateError('Unknown report rate Hz: $reportRateHz');
    }

    final raw = _requireRawBlocks(card, 'commitReportRate');
    final c2 = raw.reportRateDpi;
    if (c2 == null || c2.length != 3) {
      throw StateError('commitReportRate: C2 raw block is unavailable');
    }
    final dataBlock = Uint8List.fromList(c2);
    dataBlock[0] = wireValue;
    await session.setReportRate(dataBlock);
    _updateRawBlocks(card, raw.copyWith(reportRateDpi: dataBlock));
  }

  Future<void> commitDpiLevel(DiscoveredCardState card, int dpiLevel) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitDpiLevel: no session');
    }

    const translate = TranslationCodec();
    final wireValue = translate.dpiCurrentLevelDisplayToWire(dpiLevel);
    if (wireValue == null) {
      throw StateError('Invalid DPI level: $dpiLevel');
    }

    final raw = _requireRawBlocks(card, 'commitDpiLevel');
    final c2 = raw.reportRateDpi;
    if (c2 == null || c2.length != 3) {
      throw StateError('commitDpiLevel: C2 raw block is unavailable');
    }
    final dataBlock = Uint8List.fromList(c2);
    dataBlock[1] = wireValue;
    await session.setReportRate(dataBlock);
    _updateRawBlocks(card, raw.copyWith(reportRateDpi: dataBlock));
  }

  /// Commits staged DPI value changes into the 0xC4 table.
  ///
  /// Encodes each staged level into the hydrated 16-byte snapshot and writes
  /// the complete shared block back.
  Future<void> commitDpiValues(
    DiscoveredCardState card,
    Map<int, int> levelValues,
  ) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitDpiValues: no session');
    }

    final caps = DeviceCapabilityStore.forDevice(card.devId);
    final enc = caps?.dpi?.wireProfile;
    if (enc == null) {
      throw StateError(
        'commitDpiValues: no L2 DPI wire profile for ${card.devId}',
      );
    }

    final raw = _requireRawBlocks(card, 'commitDpiValues');
    final current = raw.dpiTable;
    if (current == null || current.length != 16) {
      throw StateError('commitDpiValues: C4 raw block is unavailable');
    }

    const translate = TranslationCodec();
    final dataBlock = Uint8List.fromList(current);
    for (final e in levelValues.entries) {
      final idx = e.key - 1; // 1-based level -> 0-based slot
      if (idx < 0 || idx >= 8) continue;
      final wire = translate.dpiDisplayToWireUnit(e.value, profile: enc);
      if (wire == null) {
        throw StateError('DPI value ${e.value} not encodable on this sensor');
      }
      // C4 stores eight two-byte big-endian DPI values.
      dataBlock[idx * 2] = (wire >> 8) & 0xFF;
      dataBlock[idx * 2 + 1] = wire & 0xFF;
    }

    await session.setDpiTable(dataBlock);
    _updateRawBlocks(card, raw.copyWith(dpiTable: dataBlock));
  }

  /// Commits staged DPI RGB color changes into the 0xC6 block.
  Future<void> commitDpiRgb(
    DiscoveredCardState card,
    Map<int, String> levelColors,
  ) async {
    final caps = DeviceCapabilityStore.forDevice(card.devId);
    if (!(caps?.dpi?.rgbPerStage ?? false)) {
      debugPrint(
        '[scope] ${card.displayName}: skipping commitDpiRgb because rgbPerStage is false',
      );
      return;
    }

    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitDpiRgb: no session');
    }

    final raw = _requireRawBlocks(card, 'commitDpiRgb');
    final current = raw.dpiRgb;
    if (current == null || current.length != 24) {
      throw StateError('commitDpiRgb: C6 raw block is unavailable');
    }

    final dataBlock = Uint8List.fromList(current);
    for (final e in levelColors.entries) {
      final idx = e.key - 1; // 1-based level -> 0-based slot
      if (idx < 0 || idx >= 8) continue;
      final rgb = _hexToRgb(e.value);
      dataBlock[idx * 3] = rgb[0];
      dataBlock[idx * 3 + 1] = rgb[1];
      dataBlock[idx * 3 + 2] = rgb[2];
    }

    await session.setDpiRgb(dataBlock);
    _updateRawBlocks(card, raw.copyWith(dpiRgb: dataBlock));
  }

  /// Commits the whole rearranged DPI stage list per FR-DPI-003.
  ///
  /// [stagedLevels] is the post-add/remove active list (1..N, already
  /// rearranged toward slot 1 by the BLoC). The full 8-slot 0xC4 table is
  /// built with the active stages' values + the tail filled with the catalog
  /// default, and the 0xC2 active mask is set to the first [activeCount] bits.
  ///
  /// why: committing the whole list (not incremental removes) avoids the
  /// re-index-vs-raw-slot mismatch when multiple stages change before Save.
  Future<void> commitDpiStages(
    DiscoveredCardState card,
    List<DpiStageData> stagedLevels,
    int activeCount,
  ) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitDpiStages: no session');
    }
    _requireRawBlocks(card, 'commitDpiStages');

    final caps = DeviceCapabilityStore.forDevice(card.devId);
    final dpi = caps?.dpi;
    final enc = dpi?.wireProfile;
    if (enc == null) {
      throw StateError(
        'commitDpiStages: no L2 DPI wire profile for ${card.devId}',
      );
    }
    final capLevels = dpi?.levels;
    if (capLevels == null || capLevels.isEmpty) {
      throw StateError(
        'commitDpiStages: no catalog DPI levels for ${card.devId}',
      );
    }
    const translate = TranslationCodec();

    final defaultDpi = capLevels.last.value;
    final defaultWire = translate.dpiDisplayToWireUnit(
      defaultDpi,
      profile: enc,
    );
    if (defaultWire == null) {
      throw StateError('commitDpiStages: default DPI not encodable');
    }

    // 1. Build the full 8-slot 0xC4 DPI values wire table: active stages first, then default-fill.
    final dataBlock = Uint8List(16);
    for (var i = 0; i < 8; i++) {
      final stage = i < stagedLevels.length ? stagedLevels[i] : null;
      final wire = stage == null
          ? defaultWire
          : translate.dpiDisplayToWireUnit(stage.value, profile: enc);
      if (wire == null) {
        throw StateError(
          'commitDpiStages: value not encodable at slot ${i + 1}',
        );
      }
      // C4 stores eight two-byte big-endian DPI values.
      dataBlock[i * 2] = (wire >> 8) & 0xFF;
      dataBlock[i * 2 + 1] = wire & 0xFF;
    }
    await session.setDpiTable(dataBlock);

    // 2. Build the full 8-slot 0xC6 DPI RGB colors wire table: active stage colors first, then default-fill.
    Uint8List? rgbBlock;
    if (dpi?.rgbPerStage ?? false) {
      rgbBlock = Uint8List(24);
      for (var i = 0; i < 8; i++) {
        final stage = i < stagedLevels.length ? stagedLevels[i] : null;
        final colorHex = stage?.color ?? _defaultColorForSlot(capLevels, i);
        final rgb = _hexToRgb(colorHex);
        rgbBlock[i * 3] = rgb[0];
        rgbBlock[i * 3 + 1] = rgb[1];
        rgbBlock[i * 3 + 2] = rgb[2];
      }
      await session.setDpiRgb(rgbBlock);
    }

    // 3. 0xC2 active mask: first activeCount bits set.
    final latestRaw = _requireRawBlocks(card, 'commitDpiStages');
    final c2 = latestRaw.reportRateDpi;
    if (c2 == null || c2.length != 3) {
      throw StateError('commitDpiStages: C2 raw block is unavailable');
    }
    final infoBlock = Uint8List.fromList(c2);
    infoBlock[2] = (1 << activeCount) - 1;
    await session.setReportRate(infoBlock);

    _updateRawBlocks(
      card,
      latestRaw.copyWith(
        dpiTable: dataBlock,
        dpiRgb: rgbBlock ?? latestRaw.dpiRgb,
        reportRateDpi: infoBlock,
      ),
    );
  }

  static String _defaultColorForSlot(List<DpiLevel> capLevels, int index) {
    if (index < capLevels.length) {
      final c = capLevels[index].color;
      if (c.isNotEmpty) return c;
    }
    return '#FFFFFF';
  }

  /// Commits the complete catalog default for the Performance page.
  ///
  /// The reset is an application-defined catalog reset, not a guessed
  /// firmware factory-reset opcode. C4 receives the catalog DPI table, C6 is
  /// written only for products with per-stage RGB, and C2 receives the
  /// catalog report rate, current level, and active-stage mask.
  Future<void> commitDpiConfigurationDefaults(
    DiscoveredCardState card, {
    required int reportRateHz,
    required int dpiLevel,
    required List<DpiStageData> defaultLevels,
    required int activeCount,
  }) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitDpiConfigurationDefaults: no session');
    }
    final raw = _requireRawBlocks(card, 'commitDpiConfigurationDefaults');

    final caps = DeviceCapabilityStore.forDevice(card.devId);
    final dpi = caps?.dpi;
    final enc = dpi?.wireProfile;
    if (enc == null) {
      throw StateError(
        'commitDpiConfigurationDefaults: no L2 DPI wire profile for '
        '${card.devId}',
      );
    }
    if (defaultLevels.isEmpty ||
        defaultLevels.length > 8 ||
        activeCount < 1 ||
        activeCount > 8 ||
        activeCount > defaultLevels.length) {
      throw StateError(
        'commitDpiConfigurationDefaults: invalid catalog DPI defaults',
      );
    }

    const translate = TranslationCodec();
    final reportRateWire = translate.reportRateHzToWire(reportRateHz);
    if (reportRateWire == null) {
      throw StateError(
        'commitDpiConfigurationDefaults: unknown report rate $reportRateHz',
      );
    }
    final dpiLevelWire = translate.dpiCurrentLevelDisplayToWire(dpiLevel);
    if (dpiLevelWire == null || dpiLevel > activeCount) {
      throw StateError(
        'commitDpiConfigurationDefaults: invalid DPI level $dpiLevel',
      );
    }

    final capLevels = dpi?.levels;
    if (capLevels == null || capLevels.isEmpty) {
      throw StateError(
        'commitDpiConfigurationDefaults: no catalog DPI levels for '
        '${card.devId}',
      );
    }
    final defaultWire = translate.dpiDisplayToWireUnit(
      capLevels.last.value,
      profile: enc,
    );
    if (defaultWire == null) {
      throw StateError(
        'commitDpiConfigurationDefaults: default DPI not encodable',
      );
    }

    final dataBlock = Uint8List(16);
    for (var i = 0; i < 8; i++) {
      final stage = i < defaultLevels.length ? defaultLevels[i] : null;
      final wire = stage == null
          ? defaultWire
          : translate.dpiDisplayToWireUnit(stage.value, profile: enc);
      if (wire == null) {
        throw StateError(
          'commitDpiConfigurationDefaults: value not encodable at slot '
          '${i + 1}',
        );
      }
      dataBlock[i * 2] = (wire >> 8) & 0xFF;
      dataBlock[i * 2 + 1] = wire & 0xFF;
    }
    await session.setDpiTable(dataBlock);
    _updateRawBlocks(card, raw.copyWith(dpiTable: dataBlock));

    if (dpi?.rgbPerStage ?? false) {
      final defaultColor = _defaultDpiColorHex(card);
      final defaultRgb = _hexToRgb(defaultColor);
      final rgbBlock = Uint8List(24);
      for (var i = 0; i < 8; i++) {
        final stage = i < defaultLevels.length ? defaultLevels[i] : null;
        final color = stage?.color;
        final rgb = color == null || color.isEmpty
            ? defaultRgb
            : _hexToRgb(color);
        rgbBlock[i * 3] = rgb[0];
        rgbBlock[i * 3 + 1] = rgb[1];
        rgbBlock[i * 3 + 2] = rgb[2];
      }
      final rgbRaw = raw.dpiRgb;
      if (rgbRaw == null || rgbRaw.length != 24) {
        throw StateError(
          'commitDpiConfigurationDefaults: C6 raw block is unavailable',
        );
      }
      await session.setDpiRgb(rgbBlock);
      final latestRaw = _requireRawBlocks(
        card,
        'commitDpiConfigurationDefaults',
      );
      _updateRawBlocks(card, latestRaw.copyWith(dpiRgb: rgbBlock));
    }

    final activeMask = (1 << activeCount) - 1;
    final latestRaw = _requireRawBlocks(card, 'commitDpiConfigurationDefaults');
    final c2 = latestRaw.reportRateDpi;
    if (c2 == null || c2.length != 3) {
      throw StateError(
        'commitDpiConfigurationDefaults: C2 raw block is unavailable',
      );
    }
    final infoBlock = Uint8List.fromList(c2);
    infoBlock[0] = reportRateWire;
    infoBlock[1] = dpiLevelWire;
    infoBlock[2] = activeMask;
    await session.setReportRate(infoBlock);
    _updateRawBlocks(card, latestRaw.copyWith(reportRateDpi: infoBlock));
  }

  /// Default RGB color (hex) for the refilled slot, from the catalog.
  String _defaultDpiColorHex(DiscoveredCardState card) {
    final caps = DeviceCapabilityStore.forDevice(card.devId);
    final levels = caps?.dpi?.levels;
    if (levels != null && levels.isNotEmpty) {
      final last = levels.last.color;
      if (last.isNotEmpty) return last;
    }
    return '#FFFFFF'; // mock default slot 8 = White
  }

  /// Parse `#RRGGBB` → [r, g, b].
  static List<int> _hexToRgb(String hex) {
    final s = hex.replaceAll('#', '');
    if (s.length != 6) return [255, 255, 255];
    return [
      int.parse(s.substring(0, 2), radix: 16),
      int.parse(s.substring(2, 4), radix: 16),
      int.parse(s.substring(4, 6), radix: 16),
    ];
  }

  /// Commits ripple control + angle snap into the 18-byte 0xD4 block.
  ///
  /// why: sensor tuning shares one block with LOD/debounce/sleep/wheel, so the
  /// hydrated raw snapshot is patched and only the two tuning bytes are replaced.
  Future<void> commitSensorTuning(
    DiscoveredCardState card,
    bool rippleControl,
    bool angleSnap,
  ) {
    return _commitSensorOtherPatch(
      card,
      'commitSensorTuning',
      rippleEnabled: rippleControl,
      angleSnapEnabled: angleSnap,
    );
  }

  /// Commits the Angle Tune enable flag and value into the D4 block.
  ///
  /// why: angle tune shares one block with ripple/angle snap/LOD/debounce/sleep/wheel,
  /// so the hydrated raw snapshot is patched before SET.
  Future<void> commitAngleTune(
    DiscoveredCardState card,
    bool enabled,
    int wireValue,
  ) {
    return _commitSensorOtherPatch(
      card,
      'commitAngleTune',
      angleTuneEnabled: enabled,
      angleTuneWire: wireValue,
    );
  }

  /// Commits the LOD value into the 18-byte 0xD4 block.
  ///
  /// why: LOD shares one block with ripple/angle snap/angle tune/debounce/sleep/wheel,
  /// so the hydrated raw snapshot is patched before SET.
  Future<void> commitLod(DiscoveredCardState card, int wire) {
    return _commitSensorOtherPatch(card, 'commitLod', lodWire: wire);
  }

  /// Commits the performance mode into the 18-byte 0xD4 block.
  ///
  /// TODO(mock): real performance semantics pending; this just writes the
  /// selected wire value into the performance byte.
  Future<void> commitPerformance(DiscoveredCardState card, int wire) {
    return _commitSensorOtherPatch(
      card,
      'commitPerformance',
      performanceWire: wire,
    );
  }

  /// Commits the button debounce index into the 18-byte 0xD4 block.
  ///
  /// why: debounce is at byte index 13, per the 18-byte layout.
  Future<void> commitDebounce(DiscoveredCardState card, int wire) {
    return _commitSensorOtherPatch(card, 'commitDebounce', debounceWire: wire);
  }

  /// Commits the sleep time index into the 18-byte 0xD4 block.
  ///
  /// why: sleep is at byte index 15, per the 18-byte layout.
  Future<void> commitSleep(DiscoveredCardState card, int wire) {
    return _commitSensorOtherPatch(card, 'commitSleep', sleepWire: wire);
  }

  /// Commits the wheel direction invert into the 18-byte 0xD4 block.
  ///
  /// why: L5 owns wire encoding; wheel direction is tri-state (0xFF/0x0F),
  /// so a raw 1/0 would read back as neither on nor off.
  Future<void> commitWheelInvert(DiscoveredCardState card, bool invert) {
    return _commitSensorOtherPatch(
      card,
      'commitWheelInvert',
      wheelInvert: invert,
    );
  }

  /// Patches the hydrated D4 snapshot with every staged semantic parameter
  /// in one L5-owned operation before one SET. This preserves untouched bytes.
  Future<void> commitParameterSettings(
    DiscoveredCardState card,
    ParameterSettingsPatch patch,
  ) {
    return _commitSensorOtherPatch(
      card,
      'commitParameterSettings',
      rippleEnabled: patch.rippleEnabled,
      angleSnapEnabled: patch.angleSnapEnabled,
      angleTuneEnabled: patch.angleTuneEnabled,
      angleTuneWire: patch.angleTuneWire,
      lodWire: patch.lodWire,
      performanceWire: patch.performanceWire,
      debounceWire: patch.debounceWire,
      sleepWire: patch.sleepWire,
      wheelInvert: patch.wheelInvert,
    );
  }

  /// Commits one semantic patch to the live 8-byte 0xE2 backlight block.
  ///
  /// why: preserve firmware-owned values the app cannot currently classify.
  /// The M7X PRO can report an unknown E2 enable byte; a brightness-only edit
  /// must not replace that byte. L5 owns the documented E2 positions.
  Future<void> commitRgbBacklight(
    DiscoveredCardState card,
    RgbBacklightPatch patch,
  ) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitRgbBacklight: no session');
    }
    final raw = _requireRawBlocks(card, 'commitRgbBacklight');
    final e2 = raw.rgbBacklight;
    if (e2 == null || e2.length != 8) {
      throw StateError('commitRgbBacklight: E2 raw block is unavailable');
    }
    final dataBlock = await session.setRgbBacklightPatch(
      e2,
      modeId: patch.modeId,
      brightness: patch.brightness,
      speed: patch.speed,
      red: patch.red,
      green: patch.green,
      blue: patch.blue,
      sleepWire: patch.sleepWire,
    );
    _updateRawBlocks(card, raw.copyWith(rgbBacklight: dataBlock));
  }

  /// Persist BLoC-synced settings after successful Save (cache for re-entry).
  void putSettings(DiscoveredCardState card, DeviceSettingsState settings) {
    final path = _pathForCard(card);
    if (path == null) return;
    final current = _settings[path];
    _settings[path] = current?.rawBlocks != null
        ? settings.copyWith(rawBlocks: current!.rawBlocks)
        : settings;
    settingsVersion.value++;
  }

  DeviceSettingsGateway? _sessionForCard(DiscoveredCardState card) {
    final path = _pathForCard(card);
    return path == null ? null : _sessions[path];
  }

  String? _pathForCard(DiscoveredCardState card) {
    return card.deviceKey.isEmpty ? null : card.deviceKey;
  }

  /// Subscribe to device OSD battery/charging pushes (real-time from device).
  void _startLiveBattery(DeviceSettingsGateway session) {
    final path = session.info.deviceKey;
    _sessions[path] = session;
    _bindBatteryPush(session);
    _bindPerformancePush(session);
    // Polling for battery and charging — disabled (OSD is real-time source).
    // _ensureBatteryPollTimer();
  }

  /// Live OSD battery (report 9 opcode 2) → patch existing card.
  void _bindBatteryPush(DeviceSettingsGateway session) {
    final path = session.info.deviceKey;
    _batterySubs.remove(path)?.cancel();
    _batterySubs[path] = session.batteryPushes.listen((b) {
      _patchBattery(path, b, source: 'osd');
    });
  }

  /// Live OSD performance (report 9 opcode 1) → semantic event for L3.
  void _bindPerformancePush(DeviceSettingsGateway session) {
    final path = session.info.deviceKey;
    _performanceSubs.remove(path)?.cancel();
    _performanceSubs[path] = session.performancePushes.listen((event) {
      final settings = _settings[path];
      final translate = const TranslationCodec();
      final dpiLevel = translate.dpiCurrentLevelWireToDisplay(event.dpiLevel);
      final reportRateHz = translate.reportRateWireToHz(event.reportRateWire);
      final reportRateLabel = translate.reportRateWireToLabel(
        event.reportRateWire,
      );

      // The device is the source of truth for physical button changes. Keep
      // the L4 snapshot current so a settings page opened after the event
      // starts from the actual active DPI/report-rate values.
      if (settings != null) {
        _settings[path] = settings.copyWith(
          dpiActiveIndex: dpiLevel,
          reportRateHz: reportRateHz,
          reportRateLabel: reportRateLabel,
        );
        settingsVersion.value++;
      }

      final dpiLabel = _dpiOsdLabel(
        dpiLevel,
        settings,
        pushDpiValue: event.dpiValue,
      );
      final osdEvent = OsdPerformanceEvent(
        deviceId: session.info.devId,
        reportRateLabel: reportRateLabel,
        reportRateHz: reportRateHz,
        dpiLevel: dpiLevel,
        dpiLabel: dpiLabel,
      );
      _publishOsdEvent(osdEvent);
    });
  }

  /// Emits the same semantic OSD event after a UI-initiated C2 write has
  /// succeeded. The device does not emit report-9 for those writes, unlike a
  /// physical DPI/report-rate button change.
  void _emitSavedPerformanceOsd(DeviceSettingsState settings) {
    final dpiLevel = settings.dpiActiveIndex;
    if (dpiLevel == null) return;

    final reportRateHz = settings.reportRateHz;
    _publishOsdEvent(
      OsdPerformanceEvent(
        deviceId: settings.devId,
        reportRateLabel: reportRateHz == null
            ? settings.reportRateLabel
            : '$reportRateHz Hz',
        reportRateHz: reportRateHz,
        dpiLevel: dpiLevel,
        dpiLabel: _dpiOsdLabel(dpiLevel, settings),
      ),
    );
  }

  void _publishOsdEvent(OsdPerformanceEvent event) {
    if (!_osdEvents.isClosed) {
      _osdEvents.add(event);
    }
  }

  String _dpiOsdLabel(
    int level,
    DeviceSettingsState? settings, {
    int? pushDpiValue,
  }) {
    final levels = settings?.dpiLevels;
    if (levels != null) {
      for (final stage in levels) {
        if (stage.level == level) return '${stage.value} DPI';
      }
    }
    if (pushDpiValue != null && pushDpiValue > 0) {
      return '$pushDpiValue DPI';
    }
    return 'Level $level';
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
  //   final snapshot = Map<String, DeviceSettingsGateway>.from(_sessions);
  //   for (final entry in snapshot.entries) {
  //     final path = entry.key;
  //     final session = entry.value;
  //     if (!session.isAlive) continue;
  //     debugPrint('[scope] poll A4 ${session.info.displayName}');
  //     final battery = await _queryBattery(session);
  //     if (battery == null) continue;
  //     if (!session.isAlive || !_cards.containsKey(path)) continue;
  //     _patchBattery(path, battery, source: 'poll');
  //   }
  // }

  void _startLiveStatus(DeviceSettingsGateway session) {
    final path = session.info.deviceKey;
    _statusSubs[path]?.cancel();
    _statusSubs[path] = session.statusPushes.listen((s) {
      _patchDeviceStatus(path, s, session);
    });
  }

  void _patchDeviceStatus(
    String deviceKey,
    DeviceStatusResult s,
    DeviceSettingsGateway session,
  ) {
    final list = List<DiscoveredCardState>.from(cards.value);
    final i = list.indexWhere(
      (c) =>
          c.deviceKey.toLowerCase() == deviceKey.toLowerCase() ||
          c.devId.toLowerCase() == deviceKey.toLowerCase(),
    );
    if (i < 0) return;
    final old = list[i];
    final wasAsleep = !old.isAwake;
    final updated = old.copyWith(
      isAwake: s.isAwake,
    );
    list[i] = updated;
    _cards[deviceKey] = updated;
    cards.value = List.unmodifiable(list);
    debugPrint(
      '[scope] patched card status ${updated.displayName}: '
      'isAwake=${s.isAwake} (wasAsleep=$wasAsleep)',
    );

    // Trigger auto-requery if transitioning from asleep -> awake
    if (s.isAwake && wasAsleep) {
      _triggerWakeRequery(session);
    }
  }

  Future<void> _triggerWakeRequery(DeviceSettingsGateway session) async {
    final path = session.info.deviceKey;
    if (_reQueryingPaths.contains(path)) return;
    _reQueryingPaths.add(path);
    debugPrint(
      '[scope] waking up: triggering background telemetry re-query for ${session.info.displayName}',
    );
    try {
      final battery = await _queryBattery(session);
      final firmware = await _queryFirmware(session);
      if (!session.isAlive) return;
      if (battery != null || firmware != null) {
        _upsert(session, battery, firmware);
        if (battery != null) {
          _evaluateLowBattery(session.info.deviceKey, battery);
        }
      }
    } catch (e) {
      debugPrint('[scope] wake re-query soft-fail: $e');
    } finally {
      _reQueryingPaths.remove(path);
    }
  }

  void _patchBattery(
    String deviceKey,
    BatteryResult b, {
    required String source,
  }) {
    final list = List<DiscoveredCardState>.from(cards.value);
    final i = list.indexWhere(
      (c) =>
          c.deviceKey.toLowerCase() == deviceKey.toLowerCase() ||
          c.devId.toLowerCase() == deviceKey.toLowerCase(),
    );
    if (i < 0) return;
    final old = list[i];
    final updated = old.copyWith(
      batteryPercentage: b.percent,
      isCharging: b.isCharging,
    );
    list[i] = updated;
    _cards[deviceKey] = updated;
    cards.value = List.unmodifiable(list);
    debugPrint(
      '[scope] patched card battery ($source) ${updated.displayName}: '
      '${b.percent}% charging=${b.isCharging}',
    );
    _evaluateLowBattery(deviceKey, b);
  }

  void _reevaluateKnownBatteryLevels() {
    for (final entry in _cards.entries) {
      final card = entry.value;
      _evaluateLowBattery(
        entry.key,
        BatteryResult(
          percent: card.batteryPercentage,
          isCharging: card.isCharging,
        ),
      );
    }
  }

  void _evaluateLowBattery(String path, BatteryResult battery) {
    if (battery.percent < 0) return;
    if (!_lowBatteryAlerts.shouldNotify(
      devicePath: path,
      batteryPercent: battery.percent,
      isCharging: battery.isCharging,
      thresholdPercent: batteryLowThreshold.value,
    )) {
      return;
    }

    final card = _cards[path];
    if (card == null || _batteryLowOsdEvents.isClosed) return;
    _batteryLowOsdEvents.add(
      OsdBatteryLowEvent(
        deviceName: card.displayName,
        batteryPercent: battery.percent,
        thresholdPercent: batteryLowThreshold.value,
      ),
    );
  }

  /// Queries battery+charging via A4. Returns null on failure (device gone,
  /// query threw) so the caller can fall back to sentinels rather than hiding
  /// a verified device.
  Future<BatteryResult?> _queryBattery(DeviceSettingsGateway session) async {
    try {
      final result = await session.queryBattery();
      if (result == null) {
        debugPrint(
          '[scope] battery skipped: ${session.info.displayName} '
          'no longer alive',
        );
        return null;
      }
      debugPrint(
        '[scope] battery for ${session.info.displayName}: '
        '${result.percent}% charging=${result.isCharging}',
      );
      return result;
    } catch (e) {
      debugPrint(
        '[scope] battery query failed for '
        '${session.info.displayName}: $e',
      );
      return null;
    }
  }

  /// Queries mouse/dongle firmware via A8. Returns null on failure (best-effort).
  Future<FirmwareResult?> _queryFirmware(DeviceSettingsGateway session) async {
    try {
      final result = await session.queryFirmware();
      if (result == null) {
        debugPrint(
          '[scope] firmware skipped: ${session.info.displayName} '
          'no longer alive',
        );
        return null;
      }
      debugPrint(
        '[scope] firmware for ${session.info.displayName}: '
        'mouse=${result.mouseVersionLabel} '
        'dongle=${result.dongleVersionLabel}',
      );
      return result;
    } catch (e) {
      debugPrint(
        '[scope] firmware query failed for '
        '${session.info.displayName}: $e',
      );
      return null;
    }
  }

  /// Publishes a card for a verified [session].
  /// Battery/firmware null → sentinels ("—" on the card); session stays usable.
  void _upsert(
    DeviceSettingsGateway session,
    BatteryResult? battery, [
    FirmwareResult? firmware,
    DeviceStatusResult? status,
  ]) {
    final path = session.info.deviceKey;
    if (battery == null) {
      debugPrint(
        '[scope] no battery yet for ${session.info.displayName} '
        '— card shown with Battery —',
      );
    }
    _cards[path] = _cardStateFor(session, battery, firmware, status);
    cards.value = List.unmodifiable(_cards.values);
  }

  void _remove(String path) {
    _batterySubs.remove(path)?.cancel();
    _statusSubs.remove(path)?.cancel();
    _reQueryingPaths.remove(path);
    _performanceSubs.remove(path)?.cancel();
    _sessions.remove(path);
    _settings.remove(path);
    _lowBatteryAlerts.removeDevice(path);
    // Polling for battery and charging — disabled.
    // _stopBatteryPollTimerIfIdle();
    _cards.remove(path);
    cards.value = List.unmodifiable(_cards.values);
  }

  /// L1 → L3 bridge: catalog + optional A4/A8/A3. Unknown battery → -1 ("—").
  DiscoveredCardState _cardStateFor(
    DeviceSettingsGateway session,
    BatteryResult? battery, [
    FirmwareResult? firmware,
    DeviceStatusResult? status,
  ]) {
    final info = session.info;
    final existingCard = _cards[info.deviceKey];
    final isAwake = status?.isAwake ??
        existingCard?.isAwake ??
        session.initialDeviceStatus?.isAwake ??
        true;
    return DiscoveredCardState(
      devId: info.devId,
      displayName: info.displayName,
      connectionMode: info.connectionMode,
      // The card keeps the historical mouse-only label; Device Setting renders
      // both A8 values independently.
      firmwareVersion: _firmwareLabel(firmware).isNotEmpty
          ? _firmwareLabel(firmware)
          : (existingCard?.firmwareVersion ?? ''),
      mouseFirmwareVersion: firmware?.mouseVersionLabel ??
          existingCard?.mouseFirmwareVersion ??
          '',
      dongleFirmwareVersion: firmware?.dongleVersionLabel ??
          existingCard?.dongleFirmwareVersion ??
          '',
      deviceKey: info.deviceKey,
      batteryPercentage:
          battery?.percent ?? existingCard?.batteryPercentage ?? -1,
      isCharging: battery?.isCharging ?? existingCard?.isCharging ?? false,
      isAwake: isAwake,
      physicalHandle: null,
      imageSmall: info.imageSmall,
      imageLarge: info.imageLarge,
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
    for (final sub in _statusSubs.values) {
      await sub.cancel();
    }
    _statusSubs.clear();
    _reQueryingPaths.clear();
    for (final sub in _performanceSubs.values) {
      await sub.cancel();
    }
    _performanceSubs.clear();
    _sessions.clear();
    await _runtime.stop();
    await _osdEvents.close();
    await _batteryLowOsdEvents.close();
    _lowBatteryAlerts.clear();
    batteryLowThreshold.dispose();
    cards.dispose();
    busy.dispose();
    settingsVersion.dispose();
  }
}

/// L4 adapter from the L1 lifecycle gateway to the L4 hydration port.
///
/// The onboarding query depends on [DeviceRepository], so the L1 gateway is
/// wrapped here instead of crossing the query boundary as a concrete session.
class _GatewayDeviceRepository implements DeviceRepository {
  _GatewayDeviceRepository(this._gateway, this._card);

  final DeviceSettingsGateway _gateway;
  final DiscoveredCardState _card;

  @override
  bool get isAlive => _gateway.isAlive;

  @override
  DiscoveredCardState get card => _card;

  @override
  Future<bool> rehandshake() => _gateway.rehandshake();

  @override
  Future<ButtonMappingResult?> queryButtonMapping() =>
      _gateway.queryButtonMapping();

  @override
  Future<ReportRateDpiInfoResult?> queryReportRateDpiInfo() =>
      _gateway.queryReportRateDpiInfo();

  @override
  Future<DpiTableResult?> queryDpiTable() => _gateway.queryDpiTable();

  @override
  Future<DpiRgbResult?> queryDpiRgb() => _gateway.queryDpiRgb();

  @override
  Future<SensorOtherResult?> querySensorOther() => _gateway.querySensorOther();

  @override
  Future<RgbBacklightResult?> queryRgbBacklight() =>
      _gateway.queryRgbBacklight();
}
