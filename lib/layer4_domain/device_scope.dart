import 'dart:async';
import 'dart:convert';

import 'package:driver_hub/layer1_discovery/device_scanner.dart';
import 'package:driver_hub/layer1_discovery/device_session.dart';
import 'package:driver_hub/layer1_discovery/device_watcher.dart';
import 'package:driver_hub/layer1_discovery/discovered_device.dart';
import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_bloc.dart';
import 'package:driver_hub/layer5_codec/button_mapping_slot.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer4_domain/models/macro.dart';
import 'package:driver_hub/layer4_domain/macro_repository.dart';
import 'package:driver_hub/layer4_domain/settings_onboard_query.dart';
import 'package:driver_hub/layer5_codec/codecs/translation_codec.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:driver_hub/layer6_transport/hid_session.dart';
import 'package:driver_hub/layer6_transport/local_storage.dart';
import 'package:driver_hub/layer6_transport/macro_storage.dart';
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
  DeviceScope({DeviceScanner? scanner, MacroRepository? macroRepository})
    : _scanner = scanner ?? DeviceScanner(),
      _macroRepository = macroRepository ?? PersistentMacroRepository() {
    _watcher = DeviceWatcher(
      scanner: _scanner,
      protocolFactory: () => const MouseProtocol(),
      sessionFactory: (d) => HidSession(d.hidDevice),
      sessionCtor: DeviceSession.new,
    );
  }

  final DeviceScanner _scanner;
  final MacroRepository _macroRepository;
  late final DeviceWatcher _watcher;

  /// Verified devices as card states, keyed by device path.
  final _cards = <String, DiscoveredCardState>{};

  /// Live sessions for OSD (and optional A4 poll if re-enabled), keyed by path.
  final _sessions = <String, DeviceSession>{};

  /// OSD battery subscriptions per device path.
  final _batterySubs = <String, StreamSubscription<BatteryResult>>{};

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
      debugPrint(
        '[scope] ${session.device.entry.model} gone mid-query, '
        'skipping publish',
      );
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
      commitDpiValues: (values) => commitDpiValues(card, values),
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
      commitAngleTune: (wireValue) => commitAngleTune(card, wireValue),
      commitLod: (wire) => commitLod(card, wire),
      commitPerformance: (wire) => commitPerformance(card, wire),
      commitDebounce: (wire) => commitDebounce(card, wire),
      commitSleep: (wire) => commitSleep(card, wire),
      commitWheelInvert: (invert) => commitWheelInvert(card, invert),
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
    );
  }

  /// Load the semantic macro registry for one device from the L6 backend.
  Future<List<MacroDefinition>> loadMacros(DiscoveredCardState card) async {
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
    await session.setMacro(macro);
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

  Future<void> commitDpiLevel(DiscoveredCardState card, int dpiLevel) async {
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

  /// Commits staged DPI value changes into the 0xC4 table.
  ///
  /// Reads the current table, encodes each staged level's DPI number to wire
  /// bytes using the device's sensor encoding, and writes the full 16-byte
  /// block back (read-before-write; the C4 table is a shared block).
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

    final current = await session.queryDpiTable();
    if (current == null) {
      throw StateError('Failed to read current DPI table');
    }

    const translate = TranslationCodec();
    final dataBlock = Uint8List.fromList(current.data);
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
    final defaultDpi = capLevels.last.value;
    const translate = TranslationCodec();
    final defaultWire = translate.dpiDisplayToWireUnit(
      defaultDpi,
      profile: enc,
    );
    if (defaultWire == null) {
      throw StateError('commitDpiStages: default DPI not encodable');
    }

    // Build the full 8-slot wire table: active stages first, then default-fill.
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

    // 0xC6 DPI RGB only for per-stage devices (M7X/PRO); M7XSE NAKs the SET.
    if (caps?.dpi?.rgbPerStage ?? false) {
      final defaultColor = _defaultDpiColorHex(card);
      final defaultRgb = _hexToRgb(defaultColor);
      final rgbBlock = Uint8List(24);
      for (var i = 0; i < 8; i++) {
        final stage = i < stagedLevels.length ? stagedLevels[i] : null;
        final colorHex = stage?.color;
        final isDefault = colorHex == null || colorHex.isEmpty;
        final c = isDefault ? defaultRgb : _hexToRgb(colorHex);
        rgbBlock[i * 3] = c[0];
        rgbBlock[i * 3 + 1] = c[1];
        rgbBlock[i * 3 + 2] = c[2];
      }
      await session.setDpiRgb(rgbBlock);
    }

    // 0xC2 active mask: first activeCount bits set.
    final current = await session.queryReportRateDpiInfo();
    if (current == null) {
      throw StateError('Failed to read current report rate/DPI block');
    }
    final newMask = (1 << activeCount) - 1;
    final infoBlock = Uint8List(3);
    infoBlock[0] = current.reportRate;
    infoBlock[1] = current.dpiCurrentLevel;
    infoBlock[2] = newMask;
    await session.setReportRate(infoBlock);
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
      await session.setDpiRgb(rgbBlock);
    }

    final activeMask = (1 << activeCount) - 1;
    await session.setReportRate(
      Uint8List.fromList([reportRateWire, dpiLevelWire, activeMask]),
    );
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
    // so a raw 1/0 would read back as neither on nor off. 18-byte layout:
    // ripple at [0], angleSnap at [2].
    const translate = TranslationCodec();
    final dataBlock = Uint8List.fromList(current.data);
    dataBlock[0] = translate.triStateBoolToWire(rippleControl);
    dataBlock[2] = translate.triStateBoolToWire(angleSnap);

    await session.setSensorOther(dataBlock);
  }

  /// Commits angle tune value into the 14-byte 0xD4 block.
  ///
  /// why: angle tune shares one block with ripple/angle snap/LOD/debounce/sleep/wheel,
  /// so the current block is read first and only the angle tune byte is replaced.
  Future<void> commitAngleTune(DiscoveredCardState card, int wireValue) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitAngleTune: no session');
    }

    final current = await session.querySensorOther();
    if (current == null) {
      throw StateError('Failed to read current sensor/other block');
    }

    // why: angle tune VALUE is at byte index 7 in the 18-byte 0xD4 block
    // [angleTune(6), angleValue(7)]. The angleTune ON/OFF toggle is at [6].
    final dataBlock = Uint8List.fromList(current.data);
    dataBlock[7] = wireValue;

    await session.setSensorOther(dataBlock);
  }

  /// Commits the LOD value into the 14-byte 0xD4 block.
  ///
  /// why: LOD shares one block with ripple/angle snap/angle tune/debounce/sleep/wheel,
  /// so the current block is read first and only the LOD byte is replaced.
  Future<void> commitLod(DiscoveredCardState card, int wire) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitLod: no session');
    }

    final current = await session.querySensorOther();
    if (current == null) {
      throw StateError('Failed to read current sensor/other block');
    }

    // why: LOD is at byte index 4 in the 18-byte 0xD4 block.
    final dataBlock = Uint8List.fromList(current.data);
    dataBlock[4] = wire;

    await session.setSensorOther(dataBlock);
  }

  /// Commits the performance mode into the 14-byte 0xD4 block.
  ///
  /// TODO(mock): real performance semantics pending; this just writes the
  /// selected wire value into the performance byte.
  Future<void> commitPerformance(DiscoveredCardState card, int wire) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitPerformance: no session');
    }

    final current = await session.querySensorOther();
    if (current == null) {
      throw StateError('Failed to read current sensor/other block');
    }

    // why: performance is at byte index 9 in the 18-byte 0xD4 block.
    final dataBlock = Uint8List.fromList(current.data);
    dataBlock[9] = wire;

    await session.setSensorOther(dataBlock);
  }

  /// Commits the button debounce index into the 14-byte 0xD4 block.
  ///
  /// why: debounce is at byte index 11, per the 14-byte layout
  /// [... performance(4), 0..0, debounce(11), sleep(12), wheel(13)].
  Future<void> commitDebounce(DiscoveredCardState card, int wire) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitDebounce: no session');
    }

    final current = await session.querySensorOther();
    if (current == null) {
      throw StateError('Failed to read current sensor/other block');
    }

    final dataBlock = Uint8List.fromList(current.data);
    dataBlock[13] = wire;

    await session.setSensorOther(dataBlock);
  }

  /// Commits the sleep time index into the 14-byte 0xD4 block.
  ///
  /// why: sleep is at byte index 12, per the 14-byte layout.
  Future<void> commitSleep(DiscoveredCardState card, int wire) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitSleep: no session');
    }

    final current = await session.querySensorOther();
    if (current == null) {
      throw StateError('Failed to read current sensor/other block');
    }

    final dataBlock = Uint8List.fromList(current.data);
    dataBlock[15] = wire;

    await session.setSensorOther(dataBlock);
  }

  /// Commits the wheel direction invert into the 14-byte 0xD4 block.
  ///
  /// why: L5 owns wire encoding; wheel direction is tri-state (0xFF/0x0F),
  /// so a raw 1/0 would read back as neither on nor off.
  Future<void> commitWheelInvert(DiscoveredCardState card, bool invert) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitWheelInvert: no session');
    }

    final current = await session.querySensorOther();
    if (current == null) {
      throw StateError('Failed to read current sensor/other block');
    }

    const translate = TranslationCodec();
    final dataBlock = Uint8List.fromList(current.data);
    dataBlock[17] = translate.triStateBoolToWire(invert);

    await session.setSensorOther(dataBlock);
  }

  /// Commits the RGB backlight block as one 8-byte 0xE2 SET.
  ///
  /// why: the bloc overlays staged fields on the last-synced block before
  /// calling this, so [values] is fully resolved — build a fresh 8-byte block
  /// rather than a read-modify-write. `enable` is tri-state (0xFF/0x0F);
  /// brightness/speed are level indices; sleepTime is a catalog option index.
  Future<void> commitRgbBacklight(
    DiscoveredCardState card,
    StagedRgbBacklight values,
  ) async {
    final session = _sessionForCard(card);
    if (session == null || !session.isAlive) {
      throw StateError('commitRgbBacklight: no session');
    }

    const translate = TranslationCodec();
    final dataBlock = Uint8List(8);
    dataBlock[0] = translate.triStateBoolToWire(values.enable);
    dataBlock[1] = values.modeId & 0xFF;
    dataBlock[2] = values.brightness & 0xFF;
    dataBlock[3] = values.speed & 0xFF;
    dataBlock[4] = values.r & 0xFF;
    dataBlock[5] = values.g & 0xFF;
    dataBlock[6] = values.b & 0xFF;
    dataBlock[7] = values.sleepTime & 0xFF;

    await session.setRgbBacklight(dataBlock);
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

  void _patchBattery(
    String path,
    BatteryResult battery, {
    required String source,
  }) {
    final prev = _cards[path];
    if (prev == null) return;
    debugPrint(
      '[scope] live battery ($source) ${prev.displayName}: '
      '${battery.percent}% charging=${battery.isCharging}',
    );
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
        debugPrint(
          '[scope] battery skipped: ${session.device.entry.model} '
          'no longer alive',
        );
        return null;
      }
      debugPrint(
        '[scope] battery for ${session.device.entry.model}: '
        '${result.percent}% charging=${result.isCharging}',
      );
      return result;
    } catch (e) {
      debugPrint(
        '[scope] battery query failed for '
        '${session.device.entry.model}: $e',
      );
      return null;
    }
  }

  /// Queries mouse/dongle firmware via A8. Returns null on failure (best-effort).
  Future<FirmwareResult?> _queryFirmware(DeviceSession session) async {
    try {
      final result = await session.queryFirmware();
      if (result == null) {
        debugPrint(
          '[scope] firmware skipped: ${session.device.entry.model} '
          'no longer alive',
        );
        return null;
      }
      debugPrint(
        '[scope] firmware for ${session.device.entry.model}: '
        'mouse=${result.mouseVersionLabel} '
        'dongle=${result.dongleVersionLabel}',
      );
      return result;
    } catch (e) {
      debugPrint(
        '[scope] firmware query failed for '
        '${session.device.entry.model}: $e',
      );
      return null;
    }
  }

  /// Publishes a card for a verified [session].
  /// Battery/firmware null → sentinels ("—" on the card); session stays usable.
  void _upsert(
    DeviceSession session,
    BatteryResult? battery, [
    FirmwareResult? firmware,
  ]) {
    final path = session.device.hidDevice.path;
    if (battery == null) {
      debugPrint(
        '[scope] no battery yet for ${session.device.entry.model} '
        '— card shown with Battery —',
      );
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
  DiscoveredCardState _cardStateFor(
    DeviceSession session,
    BatteryResult? battery, [
    FirmwareResult? firmware,
  ]) {
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
