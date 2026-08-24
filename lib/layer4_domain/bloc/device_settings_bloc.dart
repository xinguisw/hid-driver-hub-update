import 'dart:async';

import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_state_view.dart';
import 'package:driver_hub/layer4_domain/button_mapping_reset.dart';
import 'package:driver_hub/layer4_domain/button_mapping_validate.dart';
import 'package:driver_hub/layer5_codec/button_mapping_slot.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer5_codec/button_action_catalog_map.dart';
import 'package:driver_hub/layer5_codec/codecs/translation_codec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

typedef ButtonMappingCommit =
    Future<void> Function(List<ButtonMappingSlot> slots);

typedef ReportRateCommit = Future<void> Function(int reportRateHz);

typedef DpiLevelCommit = Future<void> Function(int dpiLevel);

typedef DpiValuesCommit = Future<void> Function(Map<int, int> levelValues);

typedef DpiRgbCommit = Future<void> Function(Map<int, String> levelColors);

typedef DpiStagesCommit =
    Future<void> Function(List<DpiStageData> stagedLevels, int activeCount);

typedef DpiConfigurationDefaultsCommit =
    Future<void> Function(
      int reportRateHz,
      int dpiLevel,
      List<DpiStageData> defaultLevels,
      int activeCount,
    );

typedef SensorTuningCommit =
    Future<void> Function(bool rippleControl, bool angleSnap);

typedef AngleTuneCommit = Future<void> Function(int wireValue);
typedef AngleTuneSettingsCommit =
    Future<void> Function(bool enabled, int wireValue);

typedef LodCommit = Future<void> Function(int wire);

typedef PerformanceCommit = Future<void> Function(int wire);

typedef OtherFeatureCommit = Future<void> Function(int wire);

typedef WheelInvertCommit = Future<void> Function(bool invert);

/// Semantic patch for the Telink D4 Parameter Setting block.
///
/// Nullable fields mean "preserve the synchronized device value". L4 owns
/// staging; L5 owns the actual D4 byte positions and tri-state encoding.
class ParameterSettingsPatch {
  const ParameterSettingsPatch({
    this.rippleEnabled,
    this.angleSnapEnabled,
    this.angleTuneEnabled,
    this.angleTuneWire,
    this.lodWire,
    this.performanceWire,
    this.debounceWire,
    this.sleepWire,
    this.wheelInvert,
  });

  final bool? rippleEnabled;
  final bool? angleSnapEnabled;
  final bool? angleTuneEnabled;
  final int? angleTuneWire;
  final int? lodWire;
  final int? performanceWire;
  final int? debounceWire;
  final int? sleepWire;
  final bool? wheelInvert;

  bool get isEmpty =>
      rippleEnabled == null &&
      angleSnapEnabled == null &&
      angleTuneEnabled == null &&
      angleTuneWire == null &&
      lodWire == null &&
      performanceWire == null &&
      debounceWire == null &&
      sleepWire == null &&
      wheelInvert == null;
}

typedef ParameterSettingsCommit =
    Future<void> Function(ParameterSettingsPatch patch);

/// Semantic patch for the Telink E2 RGB-backlight block (FR-RGB-001..004).
///
/// Null means preserve the live E2 byte. L4 owns what the user changed, while
/// L5 owns the E2 byte positions and tri-state translation.
class RgbBacklightPatch {
  const RgbBacklightPatch({
    this.modeId,
    this.brightness,
    this.speed,
    this.red,
    this.green,
    this.blue,
    this.sleepWire,
  });

  final int? modeId;
  final int? brightness;
  final int? speed;
  final int? red;
  final int? green;
  final int? blue;
  final int? sleepWire;
}

typedef RgbBacklightCommit = Future<void> Function(RgbBacklightPatch patch);

/// FR-ARC-014c: escalation callback invoked when consecutive failures reach threshold.
///
/// L1 [DeviceScope] provides this to force session teardown/reconnect.
typedef EscalationCallback = void Function(String reason);

/// Save completed callback — UI uses this to dismiss sidebar.
typedef SaveCompletedCallback = void Function();

/// L4 notification that an on-device performance value was confirmed by its
/// write ACK and is now represented by synchronized settings.
///
/// This deliberately carries the synchronized model rather than a protocol
/// value so presentation consumers cannot bypass L4's wire translation.
typedef PerformanceSettingsSavedCallback =
    void Function(DeviceSettingsState settings);

/// Late L2 capability lookup, resolved at validation time.
///
/// why: the bloc is constructed before L2 caps finish loading, so a value
/// captured at construction is always null on first entry.
typedef CapabilitiesLookup = DeviceCapabilities? Function();

class DeviceSettingsBloc
    extends Bloc<DeviceSettingsEvent, DeviceSettingsViewState> {
  DeviceSettingsBloc({
    required this.commitButtonMapping,
    required this.commitReportRate,
    required this.commitDpiLevel,
    required this.commitDpiValues,
    this.commitDpiRgb,
    required this.commitDpiStages,
    this.commitDpiConfigurationDefaults,
    required this.commitSensorTuning,
    required this.commitAngleTune,
    this.commitAngleTuneSettings,
    required this.commitLod,
    required this.commitPerformance,
    required this.commitDebounce,
    required this.commitSleep,
    required this.commitWheelInvert,
    this.commitParameterSettings,
    required this.commitRgbBacklight,
    ButtonActionLabelFn? actionLabelOf,
    ButtonIdLabelFn? buttonIdLabelOf,
    DeviceSettingsViewState? initial,
    this.capabilities,
    this.capabilitiesLookup,
    this.onEscalationRequested,
    this.onSaveCompleted,
    this.onPerformanceSettingsSaved,
  }) : super(
         (initial ?? DeviceSettingsViewState.empty).copyWith(
           actionLabelOf: actionLabelOf,
           buttonIdLabelOf: buttonIdLabelOf,
         ),
       ) {
    on<DeviceSettingsHydrated>(_onHydrated);
    on<DeviceSettingsLivePerformanceUpdated>(_onLivePerformanceUpdated);
    on<DeviceSettingsResetButtonMappingRequested>(
      _onResetButtonMapping,
      transformer: droppable(),
    );
    on<DeviceSettingsResetDpiConfigurationRequested>(
      _onResetDpiConfiguration,
      transformer: droppable(),
    );
    on<DeviceSettingsSaveRequested>(_onSave, transformer: droppable());
    on<DeviceSettingsCancelRequested>(_onCancel);
    on<DeviceSettingsNavigationRequested>(_onNavigationRequested);
    on<DeviceSettingsButtonMappingSlotRequested>(_onButtonMappingSlotRequested);
    on<DeviceSettingsMacroMappingRequested>(_onMacroMappingRequested);
    on<DeviceSettingsSpecialComboRequested>(_onSpecialComboRequested);
    on<DeviceSettingsReportRateRequested>(_onReportRateRequested);
    on<DeviceSettingsSaveReportRateRequested>(
      _onSaveReportRate,
      transformer: droppable(),
    );
    on<DeviceSettingsSaveDpiConfigurationRequested>(
      _onSaveDpiConfiguration,
      transformer: droppable(),
    );
    on<DeviceSettingsDpiLevelRequested>(_onDpiLevelRequested);
    on<DeviceSettingsSaveDpiLevelRequested>(
      _onSaveDpiLevel,
      transformer: droppable(),
    );
    on<DeviceSettingsDpiValueRequested>(_onDpiValueRequested);
    on<DeviceSettingsDpiColorRequested>(_onDpiColorRequested);
    on<DeviceSettingsSaveDpiValuesRequested>(
      _onSaveDpiValues,
      transformer: droppable(),
    );
    on<DeviceSettingsDpiStageAddRequested>(_onDpiStageAddRequested);
    on<DeviceSettingsDpiStageRemoveRequested>(_onDpiStageRemoveRequested);
    on<DeviceSettingsSaveDpiStagesRequested>(
      _onSaveDpiStages,
      transformer: droppable(),
    );
    on<DeviceSettingsRippleControlRequested>(_onRippleControlRequested);
    on<DeviceSettingsAngleSnapRequested>(_onAngleSnapRequested);
    on<DeviceSettingsSaveSensorTuningRequested>(
      _onSaveSensorTuning,
      transformer: droppable(),
    );
    on<DeviceSettingsAngleTuneToggled>(_onAngleTuneToggled);
    on<DeviceSettingsAngleTuneValueChanged>(_onAngleTuneValueChanged);
    on<DeviceSettingsSaveAngleTuneRequested>(
      _onSaveAngleTune,
      transformer: droppable(),
    );
    on<DeviceSettingsLodRequested>(_onLodRequested);
    on<DeviceSettingsSaveLodRequested>(_onSaveLod, transformer: droppable());
    on<DeviceSettingsPerformanceRequested>(_onPerformanceRequested);
    on<DeviceSettingsSavePerformanceRequested>(
      _onSavePerformance,
      transformer: droppable(),
    );
    on<DeviceSettingsButtonDebounceRequested>(_onDebounceRequested);
    on<DeviceSettingsSaveButtonDebounceRequested>(
      _onSaveDebounce,
      transformer: droppable(),
    );
    on<DeviceSettingsSleepTimeRequested>(_onSleepRequested);
    on<DeviceSettingsSaveSleepTimeRequested>(
      _onSaveSleep,
      transformer: droppable(),
    );
    on<DeviceSettingsWheelInvertRequested>(_onWheelInvertRequested);
    on<DeviceSettingsSaveWheelInvertRequested>(
      _onSaveWheelInvert,
      transformer: droppable(),
    );
    on<DeviceSettingsSaveParameterSettingsRequested>(
      _onSaveParameterSettings,
      transformer: droppable(),
    );
    on<DeviceSettingsBacklightEnableRequested>(_onBacklightEnableRequested);
    on<DeviceSettingsBacklightModeRequested>(_onBacklightModeRequested);
    on<DeviceSettingsBacklightColorRequested>(_onBacklightColorRequested);
    on<DeviceSettingsBacklightBrightnessRequested>(
      _onBacklightBrightnessRequested,
    );
    on<DeviceSettingsBacklightSpeedRequested>(_onBacklightSpeedRequested);
    on<DeviceSettingsBacklightSleepRequested>(_onBacklightSleepRequested);
    on<DeviceSettingsSaveBacklightRequested>(
      _onSaveBacklight,
      transformer: droppable(),
    );
  }

  final ButtonMappingCommit commitButtonMapping;
  final ReportRateCommit commitReportRate;
  final DpiLevelCommit commitDpiLevel;
  final DpiValuesCommit commitDpiValues;
  final DpiRgbCommit? commitDpiRgb;
  final DpiStagesCommit commitDpiStages;
  final DpiConfigurationDefaultsCommit? commitDpiConfigurationDefaults;
  final SensorTuningCommit commitSensorTuning;
  final AngleTuneCommit commitAngleTune;
  final AngleTuneSettingsCommit? commitAngleTuneSettings;
  final LodCommit commitLod;
  final PerformanceCommit commitPerformance;
  final OtherFeatureCommit commitDebounce;
  final OtherFeatureCommit commitSleep;
  final WheelInvertCommit commitWheelInvert;
  final ParameterSettingsCommit? commitParameterSettings;
  final RgbBacklightCommit commitRgbBacklight;
  final DeviceCapabilities? capabilities;
  final CapabilitiesLookup? capabilitiesLookup;
  final EscalationCallback? onEscalationRequested;

  /// Caps in force right now: the constructor value wins, else the late lookup.
  DeviceCapabilities? get activeCapabilities =>
      capabilities ?? capabilitiesLookup?.call();
  final SaveCompletedCallback? onSaveCompleted;
  final PerformanceSettingsSavedCallback? onPerformanceSettingsSaved;

  static const int failureEscalateThreshold = 3;

  void _onHydrated(
    DeviceSettingsHydrated event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    emit(
      state.copyWith(
        synced: event.settings,
        clearStaging: true,
        clearError: true,
        consecutiveFailures: 0,
        committing: false,
      ),
    );
  }

  void _onLivePerformanceUpdated(
    DeviceSettingsLivePerformanceUpdated event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) return;

    emit(
      state.copyWith(
        synced: synced.copyWith(
          dpiActiveIndex: event.dpiLevel,
          reportRateHz: event.reportRateHz,
          reportRateLabel: event.reportRateLabel,
        ),
        clearError: true,
      ),
    );
  }

  Future<void> _onResetButtonMapping(
    DeviceSettingsResetButtonMappingRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }
    if (state.committing) return;

    final defaults = stageButtonMappingDefaults(synced.buttons);
    debugPrint(
      '[bloc] reset buttonMapping immediate commit '
      '${[for (var i = 0; i < defaults.length; i++) 'B${i + 1}=0x${defaults[i].action.toRadixString(16)}'].join(' ')}',
    );

    final validationError = validateButtonMappingStaging(
      staging: defaults,
      synced: synced,
    );
    if (validationError != null) {
      emit(state.copyWith(lastError: validationError));
      return;
    }

    final l2ValidationError = validateButtonMappingAgainstCapabilities(
      staging: defaults,
      synced: synced,
      capabilities: activeCapabilities,
    );
    if (l2ValidationError != null) {
      emit(state.copyWith(lastError: l2ValidationError));
      return;
    }

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitButtonMapping(defaults);
    } catch (e) {
      debugPrint('[bloc] reset buttonMapping failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'reset buttonMapping failed: $e',
          consecutiveFailures: failures,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        onEscalationRequested?.call(
          'reset buttonMapping failed: $e',
        );
      }
      return;
    }

    final nextSynced = packButtonsOntoSettings(
      synced,
      defaults,
      actionLabelOf: state.actionLabelOf,
      buttonIdLabelOf: state.buttonIdLabelOf,
    );
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        buttonMappingStaging: null,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
        actionLabelOf: state.actionLabelOf,
        buttonIdLabelOf: state.buttonIdLabelOf,
      ),
    );
    debugPrint('[bloc] reset buttonMapping: synced');
  }

  Future<void> _onResetDpiConfiguration(
    DeviceSettingsResetDpiConfigurationRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    if (state.committing) return;

    final synced = state.synced;
    if (synced == null) {
      emit(
        state.copyWith(
          lastError: 'reset DPI configuration: no settings loaded',
        ),
      );
      return;
    }

    final commitDefaults = commitDpiConfigurationDefaults;
    if (commitDefaults == null) {
      emit(
        state.copyWith(
          lastError: 'reset DPI configuration: commit is not wired',
        ),
      );
      return;
    }

    final caps = activeCapabilities;
    final reportRateCaps = caps?.reportRate;
    final dpiCaps = caps?.dpi;
    if (reportRateCaps == null || dpiCaps == null) {
      emit(
        state.copyWith(
          lastError: 'reset DPI configuration: capabilities unavailable',
        ),
      );
      return;
    }
    if (synced.decodeErrors.contains('reportRateDpi')) {
      emit(state.copyWith(lastError: 'DPI unavailable: decode error'));
      return;
    }

    final defaultReportRate = reportRateCaps.defaultValue;
    if (!reportRateCaps.options.contains(defaultReportRate)) {
      emit(
        state.copyWith(
          lastError:
              'reset DPI configuration: default report rate '
              '$defaultReportRate not in options ${reportRateCaps.options}',
        ),
      );
      return;
    }

    final activeCount = dpiCaps.activeLevelCount;
    final defaultLevel = dpiCaps.defaultLevel;
    final defaultLevels = [
      for (final level in dpiCaps.levels)
        DpiStageData(
          level: level.level,
          value: level.value,
          color: level.color.isEmpty ? null : level.color,
        ),
    ];
    if (defaultLevels.isEmpty ||
        activeCount < 1 ||
        activeCount > dpiCaps.maxLevels ||
        activeCount > defaultLevels.length ||
        defaultLevel < 1 ||
        defaultLevel > activeCount) {
      emit(
        state.copyWith(
          lastError: 'reset DPI configuration: invalid DPI catalog defaults',
        ),
      );
      return;
    }

    debugPrint(
      '[bloc] reset DPI configuration immediate commit '
      'rate=${defaultReportRate}Hz level=$defaultLevel active=$activeCount',
    );
    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitDefaults(
        defaultReportRate,
        defaultLevel,
        defaultLevels,
        activeCount,
      );
    } catch (e) {
      debugPrint('[bloc] reset DPI configuration failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'reset DPI configuration failed: $e',
          consecutiveFailures: failures,
        ),
      );
      if (failures >= failureEscalateThreshold) {
        onEscalationRequested?.call(
          'reset DPI configuration failed $failures consecutive times',
        );
      }
      return;
    }

    const translate = TranslationCodec();
    final reportRateWire = translate.reportRateHzToWire(defaultReportRate);
    final activeLevels = defaultLevels
        .take(activeCount)
        .toList(growable: false);
    final nextSynced = synced.copyWith(
      reportRateHz: defaultReportRate,
      reportRateLabel: reportRateWire == null
          ? synced.reportRateLabel
          : translate.reportRateWireToLabel(reportRateWire),
      dpiActiveLevelCount: activeCount,
      dpiActiveIndex: defaultLevel,
      dpiLevels: activeLevels,
    );
    final nextState = state.copyWith(
      synced: nextSynced,
      committing: false,
      consecutiveFailures: 0,
      clearError: true,
      clearReportRateStaging: true,
      clearDpiCurrentLevelStaging: true,
      clearDpiValueStaging: true,
      clearDpiStageStaging: true,
    );
    emit(nextState.copyWith(isDirty: nextState.hasAnyStaging));
    debugPrint('[bloc] reset DPI configuration: synced');
  }

  Future<void> _onSave(
    DeviceSettingsSaveRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    if (!state.isDirty || state.buttonMappingStaging == null) {
      debugPrint('[bloc] save: nothing dirty');
      return;
    }
    if (state.committing) return;

    final staging = List<ButtonMappingSlot>.from(state.buttonMappingStaging!);
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save: no synced settings'));
      return;
    }

    final validationError = validateButtonMappingStaging(
      staging: staging,
      synced: synced,
    );
    if (validationError != null) {
      emit(state.copyWith(lastError: validationError));
      return;
    }

    // L2 boundary validation against device capabilities
    final l2ValidationError = validateButtonMappingAgainstCapabilities(
      staging: staging,
      synced: synced,
      capabilities: activeCapabilities,
    );
    if (l2ValidationError != null) {
      emit(state.copyWith(lastError: l2ValidationError));
      return;
    }

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitButtonMapping(staging);
    } catch (e) {
      debugPrint('[bloc] save buttonMapping failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'button mapping save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold or timeout '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'button mapping save failed: $e',
        );
      }
      return;
    }

    final nextSynced = packButtonsOntoSettings(
      synced,
      staging,
      actionLabelOf: state.actionLabelOf,
      buttonIdLabelOf: state.buttonIdLabelOf,
    );
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        buttonMappingStaging: null,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
        actionLabelOf: state.actionLabelOf,
        buttonIdLabelOf: state.buttonIdLabelOf,
      ),
    );
    debugPrint('[bloc] save buttonMapping: synced');
    onSaveCompleted?.call();
  }

  void _onCancel(
    DeviceSettingsCancelRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    if (!state.isDirty && !state.hasAnyStaging) return;
    emit(
      state.copyWith(clearStaging: true, clearError: true, committing: false),
    );
    debugPrint('[bloc] cancel: staging wiped');
  }

  /// FR-OPS-005: navigation guard — dirty sweep, no modal.
  ///
  /// Reuses the same wipe path as Cancel (per flowchart: Yes arrow from
  /// "Is Sandbox buffer dirty?" loops back to "Wipe staging buffer for block").
  void _onNavigationRequested(
    DeviceSettingsNavigationRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    if (!state.isDirty && !state.hasAnyStaging) return;
    emit(
      state.copyWith(clearStaging: true, clearError: true, committing: false),
    );
    debugPrint('[bloc] navigation: dirty sweep');
  }

  /// User selected a catalog action for a button slot.
  ///
  /// Translates catalog ID → wire bytes via [ButtonActionCatalogMap],
  /// updates the staging buffer, and marks dirty.
  void _onButtonMappingSlotRequested(
    DeviceSettingsButtonMappingSlotRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    // why: stageButtonMappingFromLive would seed from a baseline that never decoded
    if (synced.decodeErrors.contains('buttonMapping')) {
      emit(
        state.copyWith(lastError: 'button mapping unavailable: decode error'),
      );
      return;
    }

    // Translate catalog ID → wire slot
    final slot = ButtonActionCatalogMap.catalogIdToSlot(event.catalogId);
    if (slot == null) {
      emit(
        state.copyWith(lastError: 'unknown catalog action: ${event.catalogId}'),
      );
      return;
    }

    // Initialize staging from live device values if null
    var staging =
        state.buttonMappingStaging ??
        stageButtonMappingFromLive(synced.buttons);

    // Update the slot for this button (1-based index)
    final index = event.buttonId - 1;
    if (index < 0 || index >= staging.length) {
      emit(
        state.copyWith(lastError: 'button id out of range: ${event.buttonId}'),
      );
      return;
    }

    staging = List<ButtonMappingSlot>.from(staging);
    staging[index] = slot;

    emit(
      state.copyWith(
        buttonMappingStaging: staging,
        isDirty: true,
        clearError: true,
      ),
    );

    debugPrint(
      '[bloc] button B${event.buttonId} → ${event.catalogId} '
      '(action=0x${slot.action.toRadixString(16)})',
    );
  }

  void _onMacroMappingRequested(
    DeviceSettingsMacroMappingRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }
    if (synced.decodeErrors.contains('buttonMapping')) {
      emit(
        state.copyWith(lastError: 'button mapping unavailable: decode error'),
      );
      return;
    }
    if (event.macroSlot < 1 || event.macroSlot > 16) {
      emit(
        state.copyWith(
          lastError: 'macro slot out of range: ${event.macroSlot}',
        ),
      );
      return;
    }
    var staging =
        state.buttonMappingStaging ??
        stageButtonMappingFromLive(synced.buttons);
    final index = event.buttonId - 1;
    if (index < 0 || index >= staging.length) {
      emit(
        state.copyWith(lastError: 'button id out of range: ${event.buttonId}'),
      );
      return;
    }
    staging = List<ButtonMappingSlot>.from(staging);
    staging[index] = ButtonMappingSlot(
      action: 0x14,
      param1: event.macroSlot,
      param2: 0,
      param3: 0,
    );
    emit(
      state.copyWith(
        buttonMappingStaging: staging,
        isDirty: true,
        clearError: true,
      ),
    );
    debugPrint('[bloc] button B${event.buttonId} → macro M${event.macroSlot}');
  }

  /// User selected a special combination (modifiers + key) for a button slot.
  ///
  /// Translates modifier IDs + character → wire bytes via
  /// [ButtonActionCatalogMap.buildComboSlot], updates staging, marks dirty.
  void _onSpecialComboRequested(
    DeviceSettingsSpecialComboRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    // why: same staging buffer as slot-requested — same undecoded baseline risk
    if (synced.decodeErrors.contains('buttonMapping')) {
      emit(
        state.copyWith(lastError: 'button mapping unavailable: decode error'),
      );
      return;
    }

    // Translate modifiers + char → wire slot
    final slot = ButtonActionCatalogMap.buildComboSlot(
      event.modifierIds,
      event.keyChar,
    );
    if (slot == null) {
      emit(
        state.copyWith(
          lastError:
              'invalid special combo: '
              'mods=${event.modifierIds} char="${event.keyChar}"',
        ),
      );
      return;
    }

    // Initialize staging from live device values if null
    var staging =
        state.buttonMappingStaging ??
        stageButtonMappingFromLive(synced.buttons);

    // Update the slot for this button (1-based index)
    final index = event.buttonId - 1;
    if (index < 0 || index >= staging.length) {
      emit(
        state.copyWith(lastError: 'button id out of range: ${event.buttonId}'),
      );
      return;
    }

    staging = List<ButtonMappingSlot>.from(staging);
    staging[index] = slot;

    emit(
      state.copyWith(
        buttonMappingStaging: staging,
        isDirty: true,
        clearError: true,
      ),
    );

    debugPrint(
      '[bloc] button B${event.buttonId} → special combo '
      '(action=0x${slot.action.toRadixString(16)}, '
      'p1=0x${slot.param1.toRadixString(16)}, '
      'p2=0x${slot.param2.toRadixString(16)}, '
      'p3=0x${slot.param3.toRadixString(16)})',
    );
  }

  /// User selected a report rate value.
  ///
  /// Stages the Hz value and marks dirty. Save commits to device.
  void _onReportRateRequested(
    DeviceSettingsReportRateRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    // why: baseline never decoded — staging would diff against an unknown value
    if (synced.decodeErrors.contains('reportRateDpi')) {
      emit(state.copyWith(lastError: 'report rate unavailable: decode error'));
      return;
    }

    // Validate Hz is in allowed options
    final options = synced.reportRateOptions;
    if (options != null && !options.contains(event.hz)) {
      emit(
        state.copyWith(
          lastError: 'report rate ${event.hz}Hz not in options $options',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        reportRateStaging: event.hz,
        isDirty: true,
        clearError: true,
      ),
    );

    debugPrint('[bloc] report rate staged: ${event.hz}Hz');
  }

  /// Save report rate staging to device.
  Future<void> _onSaveReportRate(
    DeviceSettingsSaveReportRateRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    if (!state.isDirty || state.reportRateStaging == null) {
      debugPrint('[bloc] save reportRate: nothing dirty');
      return;
    }
    if (state.committing) return;

    final staging = state.reportRateStaging!;
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save reportRate: no synced settings'));
      return;
    }

    final options = synced.reportRateOptions;
    if (options != null && !options.contains(staging)) {
      emit(
        state.copyWith(
          lastError: 'report rate ${staging}Hz not in options $options',
        ),
      );
      return;
    }

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitReportRate(staging);
    } catch (e) {
      debugPrint('[bloc] save reportRate failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'report rate save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold or timeout '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'report rate save failed: $e',
        );
      }
      return;
    }

    final nextSynced = synced.copyWith(reportRateHz: staging, clearError: true);
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        reportRateStaging: null,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
        actionLabelOf: state.actionLabelOf,
        buttonIdLabelOf: state.buttonIdLabelOf,
      ),
    );
    debugPrint('[bloc] save reportRate: synced');
    onPerformanceSettingsSaved?.call(nextSynced);
    onSaveCompleted?.call();
  }

  /// Saves the complete DPI configuration block in protocol-safe order.
  ///
  /// C4 owns the DPI stage table, while C2 owns report rate/current level/
  /// active-level metadata. Stage changes must reach C4 before value patches,
  /// and the C2 selection write runs after the C4 transaction. Keeping this in
  /// one handler prevents the default concurrent BLoC event processing from
  /// dropping the value save behind the level save's committing guard.
  Future<void> _onSaveDpiConfiguration(
    DeviceSettingsSaveDpiConfigurationRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    if (state.committing) return;

    final synced = state.synced;
    if (synced == null) {
      emit(
        state.copyWith(lastError: 'save DPI configuration: no synced settings'),
      );
      return;
    }

    final reportRate = state.reportRateStaging;
    final dpiLevel = state.dpiCurrentLevelStaging;
    final dpiValues = state.dpiValueStaging == null
        ? null
        : Map<int, int>.from(state.dpiValueStaging!);
    final dpiRgbColors = state.dpiRgbStaging == null
        ? null
        : Map<int, String>.from(state.dpiRgbStaging!);
    final hasStageStaging =
        state.dpiStageLevelsStaging != null ||
        state.dpiStageAddStaging ||
        state.dpiStageRemoveLevelStaging != null;
    final stagedLevels = state.dpiStageLevelsStaging == null
        ? null
        : List<DpiStageData>.from(state.dpiStageLevelsStaging!);

    if (reportRate == null &&
        dpiLevel == null &&
        (dpiValues == null || dpiValues.isEmpty) &&
        (dpiRgbColors == null || dpiRgbColors.isEmpty) &&
        !hasStageStaging) {
      debugPrint('[bloc] save DPI configuration: nothing dirty');
      return;
    }

    if (reportRate != null) {
      final options = synced.reportRateOptions;
      if (options != null && !options.contains(reportRate)) {
        emit(
          state.copyWith(
            lastError: 'report rate ${reportRate}Hz not in options $options',
          ),
        );
        return;
      }
    }

    final dpiSaveRequested =
        dpiLevel != null ||
        (dpiValues != null && dpiValues.isNotEmpty) ||
        (dpiRgbColors != null && dpiRgbColors.isNotEmpty) ||
        hasStageStaging;
    if (dpiSaveRequested && synced.decodeErrors.contains('reportRateDpi')) {
      emit(state.copyWith(lastError: 'DPI unavailable: decode error'));
      return;
    }

    final dpiCaps = activeCapabilities?.dpi;
    if (dpiLevel != null && dpiCaps != null) {
      final validLevels = dpiCaps.levels.map((l) => l.level).toList();
      if (!validLevels.contains(dpiLevel)) {
        emit(
          state.copyWith(
            lastError: 'DPI level $dpiLevel not in capabilities $validLevels',
          ),
        );
        return;
      }
    }

    if (hasStageStaging && (stagedLevels == null || stagedLevels.isEmpty)) {
      emit(state.copyWith(lastError: 'DPI stages: no staged levels'));
      return;
    }

    emit(state.copyWith(committing: true, clearError: true));

    try {
      if (reportRate != null) {
        await commitReportRate(reportRate);
      }
      if (hasStageStaging) {
        await commitDpiStages(stagedLevels!, stagedLevels.length);
      }
      if (dpiValues != null && dpiValues.isNotEmpty) {
        await commitDpiValues(dpiValues);
      }
      if (dpiRgbColors != null && dpiRgbColors.isNotEmpty && commitDpiRgb != null) {
        await commitDpiRgb!(dpiRgbColors);
      }
      if (dpiLevel != null) {
        await commitDpiLevel(dpiLevel);
      }
    } catch (e) {
      debugPrint('[bloc] save DPI configuration failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'DPI configuration save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        onEscalationRequested?.call(
          'DPI configuration save failed: $e',
        );
      }
      return;
    }

    var nextSynced = synced;
    if (reportRate != null) {
      nextSynced = nextSynced.copyWith(reportRateHz: reportRate);
    }
    if (hasStageStaging) {
      final count = stagedLevels!.length;
      var activeIndex = nextSynced.dpiActiveIndex;
      if (activeIndex != null && activeIndex > count) {
        activeIndex = 1;
      }
      nextSynced = nextSynced.copyWith(
        dpiActiveLevelCount: count,
        dpiLevels: stagedLevels,
        dpiActiveIndex: activeIndex,
      );
    }
    if (dpiValues != null && dpiValues.isNotEmpty) {
      final levels = [...?nextSynced.dpiLevels];
      for (final entry in dpiValues.entries) {
        final index = levels.indexWhere((level) => level.level == entry.key);
        if (index >= 0) {
          levels[index] = DpiStageData(
            level: entry.key,
            value: entry.value,
            color: levels[index].color,
          );
        }
      }
      nextSynced = nextSynced.copyWith(dpiLevels: levels);
    }
    if (dpiRgbColors != null && dpiRgbColors.isNotEmpty) {
      final levels = [...?nextSynced.dpiLevels];
      for (final entry in dpiRgbColors.entries) {
        final index = levels.indexWhere((level) => level.level == entry.key);
        if (index >= 0) {
          levels[index] = DpiStageData(
            level: entry.key,
            value: levels[index].value,
            y: levels[index].y,
            color: entry.value,
          );
        }
      }
      final currentDpiRgb = nextSynced.rawBlocks?.dpiRgb;
      Uint8List? updatedDpiRgb;
      if (currentDpiRgb != null && currentDpiRgb.length == 24) {
        updatedDpiRgb = Uint8List.fromList(currentDpiRgb);
        for (final entry in dpiRgbColors.entries) {
          final idx = entry.key - 1;
          if (idx >= 0 && idx < 8) {
            final rgb = _hexToRgb(entry.value);
            updatedDpiRgb[idx * 3] = rgb[0];
            updatedDpiRgb[idx * 3 + 1] = rgb[1];
            updatedDpiRgb[idx * 3 + 2] = rgb[2];
          }
        }
      }
      nextSynced = nextSynced.copyWith(
        dpiLevels: levels,
        rawBlocks: updatedDpiRgb != null
            ? nextSynced.rawBlocks?.copyWith(dpiRgb: updatedDpiRgb)
            : nextSynced.rawBlocks,
      );
    }
    if (dpiLevel != null) {
      nextSynced = nextSynced.copyWith(dpiActiveIndex: dpiLevel);
    }

    final nextState = state.copyWith(
      synced: nextSynced,
      committing: false,
      consecutiveFailures: 0,
      lastError: null,
      clearReportRateStaging: reportRate != null,
      clearDpiCurrentLevelStaging: dpiLevel != null,
      clearDpiValueStaging: dpiValues != null && dpiValues.isNotEmpty,
      clearDpiRgbStaging: dpiRgbColors != null && dpiRgbColors.isNotEmpty,
      clearDpiStageStaging: hasStageStaging,
    );
    emit(nextState.copyWith(isDirty: nextState.hasAnyStaging));
    debugPrint('[bloc] save DPI configuration: synced');
    // Only emit for actual runtime-performance selections. Editing an
    // inactive stage table/value does not change the mouse's active DPI.
    if (reportRate != null || dpiLevel != null) {
      onPerformanceSettingsSaved?.call(nextSynced);
    }
    onSaveCompleted?.call();
  }

  /// User selected a DPI level.
  ///
  /// Validates against L2 capabilities, stages the level, and marks dirty.
  void _onDpiLevelRequested(
    DeviceSettingsDpiLevelRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    // why: baseline never decoded — staging would diff against an unknown value
    if (synced.decodeErrors.contains('reportRateDpi')) {
      emit(state.copyWith(lastError: 'DPI level unavailable: decode error'));
      return;
    }

    // Validate level is in L2 capabilities
    final dpiCaps = activeCapabilities?.dpi;
    if (dpiCaps != null) {
      final validLevels = dpiCaps.levels.map((l) => l.level).toList();
      if (!validLevels.contains(event.level)) {
        emit(
          state.copyWith(
            lastError:
                'DPI level ${event.level} not in capabilities $validLevels',
          ),
        );
        return;
      }
    }

    emit(
      state.copyWith(
        dpiCurrentLevelStaging: event.level,
        isDirty: true,
        clearError: true,
      ),
    );

    debugPrint('[bloc] DPI level staged: ${event.level}');
  }

  /// Save DPI level staging to device.
  Future<void> _onSaveDpiLevel(
    DeviceSettingsSaveDpiLevelRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    if (!state.isDirty || state.dpiCurrentLevelStaging == null) {
      debugPrint('[bloc] save DPI level: nothing dirty');
      return;
    }
    if (state.committing) return;

    final staging = state.dpiCurrentLevelStaging!;
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save DPI level: no synced settings'));
      return;
    }

    // Validate level is in L2 capabilities
    final dpiCaps = activeCapabilities?.dpi;
    if (dpiCaps != null) {
      final validLevels = dpiCaps.levels.map((l) => l.level).toList();
      if (!validLevels.contains(staging)) {
        emit(
          state.copyWith(
            lastError: 'DPI level $staging not in capabilities $validLevels',
          ),
        );
        return;
      }
    }

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitDpiLevel(staging);
    } catch (e) {
      debugPrint('[bloc] save DPI level failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'DPI level save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold or timeout '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'DPI level save failed: $e',
        );
      }
      return;
    }

    final nextSynced = synced.copyWith(
      dpiActiveIndex: staging,
      clearError: true,
    );
    // why: preserve unrelated staging (e.g. dpiStageLevelsStaging for a
    // pending add/remove) — a fresh DeviceSettingsViewState would drop them,
    // so a paired SaveDpiStagesRequested would see nothing dirty.
    emit(
      state.copyWith(
        synced: nextSynced,
        dpiCurrentLevelStaging: null,
        clearDpiCurrentLevelStaging: true,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
      ),
    );
    debugPrint('[bloc] save DPI level: synced');
    onPerformanceSettingsSaved?.call(nextSynced);
    onSaveCompleted?.call();
  }

  /// User dragged a DPI value slider for a level.
  ///
  /// Snaps/validates the value against the mouse catalog's DPI range
  /// (stepMode fixed/tiered/any) and stages it per level.
  void _onDpiValueRequested(
    DeviceSettingsDpiValueRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    if (synced.decodeErrors.contains('reportRateDpi')) {
      emit(state.copyWith(lastError: 'DPI value unavailable: decode error'));
      return;
    }

    final range = activeCapabilities?.dpi?.range;
    if (range == null) {
      emit(state.copyWith(lastError: 'DPI value: no range in capabilities'));
      return;
    }

    final snapped = range.snap(event.value);
    if (snapped == null) {
      emit(
        state.copyWith(
          lastError:
              'DPI value ${event.value} out of range '
              '[${range.minDpi}, ${range.maxDpi}]',
        ),
      );
      return;
    }

    final next = {...?state.dpiValueStaging};
    next[event.level] = snapped;
    emit(
      state.copyWith(dpiValueStaging: next, isDirty: true, clearError: true),
    );

    debugPrint('[bloc] DPI value staged: level=${event.level} value=$snapped');
  }

  /// Stages a DPI RGB color by reusing the complete DPI-stage transaction.
  void _onDpiColorRequested(
    DeviceSettingsDpiColorRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }
    if (synced.decodeErrors.contains('dpiRgb')) {
      emit(state.copyWith(lastError: 'DPI RGB unavailable: decode error'));
      return;
    }

    final dpi = activeCapabilities?.dpi;
    if (dpi == null || !dpi.rgbPerStage) {
      emit(state.copyWith(lastError: 'DPI RGB unavailable for this device'));
      return;
    }
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(event.color)) {
      emit(state.copyWith(lastError: 'DPI RGB color must be #RRGGBB'));
      return;
    }

    final next = {...?state.dpiRgbStaging};
    next[event.level] = event.color.toUpperCase();
    emit(
      state.copyWith(
        dpiRgbStaging: next,
        isDirty: true,
        clearError: true,
      ),
    );
    debugPrint(
      '[bloc] DPI RGB color staged: level=${event.level} color=${event.color}',
    );
  }

  /// Save all staged DPI value changes to device.
  Future<void> _onSaveDpiValues(
    DeviceSettingsSaveDpiValuesRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    final staging = state.dpiValueStaging;
    if (staging == null || staging.isEmpty) {
      debugPrint('[bloc] save DPI values: nothing dirty');
      return;
    }
    if (state.committing) return;

    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save DPI values: no synced settings'));
      return;
    }

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitDpiValues(staging);
    } catch (e) {
      debugPrint('[bloc] save DPI values failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'DPI values save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        onEscalationRequested?.call(
          'DPI values save failed: $e',
        );
      }
      return;
    }

    final levels = [...?synced.dpiLevels];
    for (final e in staging.entries) {
      final idx = levels.indexWhere((l) => l.level == e.key);
      if (idx >= 0) {
        levels[idx] = DpiStageData(
          level: e.key,
          value: e.value,
          color: levels[idx].color,
        );
      }
    }
    final nextSynced = synced.copyWith(dpiLevels: levels, clearError: true);
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        dpiValueStaging: null,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
        actionLabelOf: state.actionLabelOf,
        buttonIdLabelOf: state.buttonIdLabelOf,
      ),
    );
    debugPrint('[bloc] save DPI values: synced');
    onSaveCompleted?.call();
  }

  /// User pressed `+` — add a DPI stage (append next-lowest inactive).
  ///
  /// Stages the add and marks dirty; commit happens on Save.
  void _onDpiStageAddRequested(
    DeviceSettingsDpiStageAddRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }
    // why: accumulate onto the staged list so multiple `+` clicks add
    // multiple stages before Save. The base is the staged list if present,
    // else the synced levels; the count comes from that same base.
    final staged = state.dpiStageLevelsStaging;
    final baseLevels = staged ?? synced.dpiLevels;
    final currentCount = baseLevels?.length ?? 0;
    final maxLevels = synced.dpiMaxLevels ?? 8;
    if (currentCount >= maxLevels) {
      emit(state.copyWith(lastError: 'cannot add: max DPI stages reached'));
      return;
    }
    final levels = [...?baseLevels];
    final newLevel = currentCount + 1;
    final defaultDpi = _defaultDpiValue(synced) ?? 1600;
    // why: the new stage's color comes from the catalog's level-default
    // color (mock: slot 1 Red ... slot 8 White), so a newly added slot shows
    // its correct default instead of null/previous color.
    final defaultColor = _defaultDpiColorForLevel(synced, newLevel);
    levels.add(
      DpiStageData(level: newLevel, value: defaultDpi, color: defaultColor),
    );
    emit(
      state.copyWith(
        dpiStageAddStaging: true,
        dpiStageLevelsStaging: levels,
        isDirty: true,
        clearError: true,
      ),
    );
    debugPrint('[bloc] DPI stage add staged');
  }

  /// User pressed `x` — remove a DPI stage (per FR-DPI-003 rearrange).
  void _onDpiStageRemoveRequested(
    DeviceSettingsDpiStageRemoveRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }
    // why: accumulate onto the staged list so multiple `x` clicks remove
    // multiple stages before Save.
    final staged = state.dpiStageLevelsStaging;
    final baseLevels = staged ?? synced.dpiLevels;
    final activeCount = baseLevels?.length ?? 0;
    if (activeCount <= 1) {
      emit(state.copyWith(lastError: 'cannot remove: at least one stage'));
      return;
    }
    // Remove the selected level; shift later stages toward slot 1.
    final levels = [...?baseLevels];
    final removed = levels.where((l) => l.level != event.level).toList();
    final reindexed = <DpiStageData>[];
    for (var i = 0; i < removed.length; i++) {
      reindexed.add(
        DpiStageData(
          level: i + 1,
          value: removed[i].value,
          color: removed[i].color,
        ),
      );
    }
    final currentLevel = state.dpiCurrentLevelStaging ?? synced.dpiActiveIndex ?? 1;
    int nextLevel;
    if (currentLevel == event.level) {
      nextLevel = currentLevel.clamp(1, reindexed.length);
    } else if (currentLevel > event.level) {
      nextLevel = currentLevel - 1;
    } else {
      nextLevel = currentLevel.clamp(1, reindexed.length);
    }
    emit(
      state.copyWith(
        dpiStageRemoveLevelStaging: event.level,
        dpiStageLevelsStaging: reindexed,
        dpiCurrentLevelStaging: nextLevel,
        isDirty: true,
        clearError: true,
      ),
    );
    debugPrint('[bloc] DPI stage remove staged: level=${event.level} (nextLevel=$nextLevel)');
  }

  /// Save the staged DPI add/remove to device.
  Future<void> _onSaveDpiStages(
    DeviceSettingsSaveDpiStagesRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    // why: a paired level-save sets committing:true, but the send queue
    // serializes the actual device writes, so this save must still run when
    // it has real staging. Only bail if this same concern is already mid-save.
    if (state.dpiStageSaveInFlight) return;
    if (!state.dpiStageAddStaging && state.dpiStageRemoveLevelStaging == null) {
      debugPrint('[bloc] save DPI stages: nothing dirty');
      return;
    }
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save DPI stages: no synced settings'));
      return;
    }

    emit(
      state.copyWith(
        committing: true,
        dpiStageSaveInFlight: true,
        clearError: true,
      ),
    );

    // why: commit the WHOLE rearranged staged list, not incremental removes.
    // The staged levels are the authoritative post-add/remove result.
    final stagedLevels = state.dpiStageLevelsStaging;
    if (stagedLevels == null || stagedLevels.isEmpty) {
      debugPrint('[bloc] save DPI stages: no staged levels');
      return;
    }

    try {
      await commitDpiStages(stagedLevels, stagedLevels.length);
      final activeLevel = state.dpiCurrentLevelStaging ?? synced.dpiActiveIndex ?? 1;
      if (activeLevel > 0 && activeLevel <= stagedLevels.length) {
        await commitDpiLevel(activeLevel);
      }
    } catch (e) {
      debugPrint('[bloc] save DPI stages failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          dpiStageSaveInFlight: false,
          lastError: 'DPI stages save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        onEscalationRequested?.call(
          'DPI stages save failed: $e',
        );
      }
      return;
    }

    // why: the staged list IS the post-add/remove result; its length is the
    // authoritative new count (handles multiple adds, single/multi removes).
    final count = stagedLevels.length;
    var activeIndex = state.dpiCurrentLevelStaging ?? synced.dpiActiveIndex;
    if (activeIndex == null || activeIndex > count) {
      activeIndex = 1;
    }
    final nextSynced = synced.copyWith(
      dpiActiveLevelCount: count,
      dpiLevels: stagedLevels,
      dpiActiveIndex: activeIndex,
      clearError: true,
    );
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        dpiStageAddStaging: false,
        dpiStageRemoveLevelStaging: null,
        dpiStageLevelsStaging: null,
        dpiStageSaveInFlight: false,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
        actionLabelOf: state.actionLabelOf,
        buttonIdLabelOf: state.buttonIdLabelOf,
      ),
    );
    debugPrint('[bloc] save DPI stages: synced (count=$count)');
    onSaveCompleted?.call();
  }

  /// Default DPI value for a newly added stage (catalog default if known).
  int? _defaultDpiValue(DeviceSettingsState synced) {
    final caps = activeCapabilities?.dpi;
    final levels = caps?.levels;
    if (levels != null && levels.isNotEmpty) {
      return levels.last.value;
    }
    return null;
  }

  /// Catalog default color for a 1-based DPI level (mock slot 1 Red ...
  /// slot 8 White). Returns null if the catalog has no color for that slot.
  String? _defaultDpiColorForLevel(DeviceSettingsState synced, int level) {
    final caps = activeCapabilities?.dpi;
    final levels = caps?.levels;
    if (levels == null) return null;
    for (final l in levels) {
      if (l.level == level && l.color.isNotEmpty) return l.color;
    }
    return null;
  }

  /// User toggled ripple control.
  ///
  /// Stages the boolean value and marks dirty. Save commits to device.
  void _onRippleControlRequested(
    DeviceSettingsRippleControlRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    // why: baseline never decoded — staging would diff against an unknown value
    if (synced.decodeErrors.contains('sensorOther')) {
      emit(
        state.copyWith(lastError: 'ripple control unavailable: decode error'),
      );
      return;
    }

    emit(
      state.copyWith(
        rippleControlStaging: event.enabled,
        isDirty: true,
        clearError: true,
      ),
    );

    debugPrint('[bloc] ripple control staged: ${event.enabled}');
  }

  /// User toggled angle snap.
  ///
  /// Stages the boolean value and marks dirty. Save commits to device.
  void _onAngleSnapRequested(
    DeviceSettingsAngleSnapRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    // why: baseline never decoded — staging would diff against an unknown value
    if (synced.decodeErrors.contains('sensorOther')) {
      emit(state.copyWith(lastError: 'angle snap unavailable: decode error'));
      return;
    }

    emit(
      state.copyWith(
        angleSnapStaging: event.enabled,
        isDirty: true,
        clearError: true,
      ),
    );

    debugPrint('[bloc] angle snap staged: ${event.enabled}');
  }

  /// Save sensor tuning staging to device.
  Future<void> _onSaveSensorTuning(
    DeviceSettingsSaveSensorTuningRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    final rippleStaging = state.rippleControlStaging;
    final angleSnapStaging = state.angleSnapStaging;
    if (rippleStaging == null && angleSnapStaging == null) {
      debugPrint('[bloc] save sensor tuning: nothing dirty');
      return;
    }
    if (state.committing) return;

    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save sensor tuning: no synced settings'));
      return;
    }

    // why: both bytes ship together — the unstaged one must carry its synced
    // value or the SET would silently flip it.
    final ripple = rippleStaging ?? synced.rippleOn ?? false;
    final angleSnap = angleSnapStaging ?? synced.angleSnapOn ?? false;

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitSensorTuning(ripple, angleSnap);
    } catch (e) {
      debugPrint('[bloc] save sensor tuning failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'sensor tuning save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold or timeout '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'sensor tuning save failed: $e',
        );
      }
      return;
    }

    final nextSynced = synced.copyWith(
      rippleOn: ripple,
      angleSnapOn: angleSnap,
      clearError: true,
    );
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        rippleControlStaging: null,
        angleSnapStaging: null,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
        actionLabelOf: state.actionLabelOf,
        buttonIdLabelOf: state.buttonIdLabelOf,
      ),
    );
    debugPrint('[bloc] save sensor tuning: synced');
    onSaveCompleted?.call();
  }

  /// User toggled angle tune enable/disable.
  ///
  /// Stages the enabled flag separately from the value, so the displayed
  /// angle always reflects live data even when the feature is toggled off.
  /// The toggle tracks on/off; the value tracks the wire index.
  void _onAngleTuneToggled(
    DeviceSettingsAngleTuneToggled event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    // why: baseline never decoded — staging would diff against an unknown value
    if (synced.decodeErrors.contains('sensorOther')) {
      emit(state.copyWith(lastError: 'angle tune unavailable: decode error'));
      return;
    }

    emit(
      state.copyWith(
        angleTuneEnabledStaging: event.enabled,
        isDirty: true,
        clearError: true,
      ),
    );

    debugPrint('[bloc] angle tune toggled: ${event.enabled}');
  }

  /// User changed angle tune value (left/right arrow).
  ///
  /// Stages the new wire value (index into catalog options) and marks dirty.
  void _onAngleTuneValueChanged(
    DeviceSettingsAngleTuneValueChanged event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    // why: baseline never decoded — staging would diff against an unknown value
    if (synced.decodeErrors.contains('sensorOther')) {
      emit(state.copyWith(lastError: 'angle tune unavailable: decode error'));
      return;
    }

    // why: L5 owns wire→label; the catalog options come from synced state.
    const translate = TranslationCodec();
    final label = translate.angleTuneWireToLabel(event.wireValue, [
      for (final option
          in synced.angleTuneOptions ?? const <AngleTuneOptionData>[])
        AngleTuneOption(wire: option.wire, label: option.label),
    ]);

    emit(
      state.copyWith(
        angleTuneStaging: event.wireValue,
        angleTuneLabelStaging: label,
        isDirty: true,
        clearError: true,
      ),
    );

    debugPrint('[bloc] angle tune value staged: ${event.wireValue}');
  }

  /// Save angle tune staging to device.
  Future<void> _onSaveAngleTune(
    DeviceSettingsSaveAngleTuneRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    final angleTuneStaging = state.angleTuneStaging;
    final enabledStaging = state.angleTuneEnabledStaging;
    if (angleTuneStaging == null && enabledStaging == null) {
      debugPrint('[bloc] save angle tune: nothing dirty');
      return;
    }
    if (state.committing) return;

    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save angle tune: no synced settings'));
      return;
    }

    final enabled = enabledStaging ?? synced.angleTuneOn;
    final wireValue = angleTuneStaging ?? synced.angleTune;
    if (enabled == null || wireValue == null) {
      emit(
        state.copyWith(
          lastError: 'angle tune save unavailable: live value missing',
        ),
      );
      return;
    }

    emit(state.copyWith(committing: true, clearError: true));

    try {
      final transactionalCommit = commitAngleTuneSettings;
      if (transactionalCommit != null) {
        await transactionalCommit(enabled, wireValue);
      } else {
        // Compatibility for isolated BLoC tests/adapters that only support a
        // value write. Production DeviceScope always supplies the paired path.
        await commitAngleTune(wireValue);
      }
    } catch (e) {
      debugPrint('[bloc] save angle tune failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'angle tune save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold or timeout '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'angle tune save failed: $e',
        );
      }
      return;
    }

    const translate = TranslationCodec();
    final label = translate.angleTuneWireToLabel(wireValue, [
      for (final option
          in synced.angleTuneOptions ?? const <AngleTuneOptionData>[])
        AngleTuneOption(wire: option.wire, label: option.label),
    ]);

    final nextSynced = synced.copyWith(
      angleTuneOn: enabled,
      angleTune: wireValue,
      angleTuneLabel: label,
      clearError: true,
    );
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        angleTuneStaging: null,
        angleTuneEnabledStaging: null,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
        actionLabelOf: state.actionLabelOf,
        buttonIdLabelOf: state.buttonIdLabelOf,
      ),
    );
    debugPrint('[bloc] save angle tune: synced');
    onSaveCompleted?.call();
  }

  /// User selected an LOD value (radio button).
  ///
  /// Stages the new wire value and marks dirty. Commit happens on Save.
  void _onLodRequested(
    DeviceSettingsLodRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    // why: baseline never decoded — staging would diff against an unknown value
    if (synced.decodeErrors.contains('sensorOther')) {
      emit(state.copyWith(lastError: 'LOD unavailable: decode error'));
      return;
    }

    emit(
      state.copyWith(lodStaging: event.wire, isDirty: true, clearError: true),
    );

    debugPrint('[bloc] LOD staged: wire=${event.wire}');
  }

  /// Save LOD staging to device.
  Future<void> _onSaveLod(
    DeviceSettingsSaveLodRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    final lodStaging = state.lodStaging;
    if (lodStaging == null) {
      debugPrint('[bloc] save LOD: nothing dirty');
      return;
    }
    if (state.committing) return;

    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save LOD: no synced settings'));
      return;
    }

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitLod(lodStaging);
    } catch (e) {
      debugPrint('[bloc] save LOD failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'LOD save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold or timeout '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'LOD save failed: $e',
        );
      }
      return;
    }

    final nextSynced = synced.copyWith(
      lodMm: lodStaging,
      lodLabel: null, // will be recomputed from wire value on next GET
      clearError: true,
    );
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        lodStaging: null,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
        actionLabelOf: state.actionLabelOf,
        buttonIdLabelOf: state.buttonIdLabelOf,
      ),
    );
    debugPrint('[bloc] save LOD: synced');
    onSaveCompleted?.call();
  }

  /// User selected a performance mode (chip button).
  ///
  /// Stages the new wire value and marks dirty. Commit happens on Save.
  void _onPerformanceRequested(
    DeviceSettingsPerformanceRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    // why: baseline never decoded — staging would diff against an unknown value
    if (synced.decodeErrors.contains('sensorOther')) {
      emit(state.copyWith(lastError: 'performance unavailable: decode error'));
      return;
    }

    emit(
      state.copyWith(
        performanceStaging: event.wire,
        isDirty: true,
        clearError: true,
      ),
    );

    debugPrint('[bloc] performance staged: wire=${event.wire}');
  }

  /// Save performance staging to device.
  Future<void> _onSavePerformance(
    DeviceSettingsSavePerformanceRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    final performanceStaging = state.performanceStaging;
    if (performanceStaging == null) {
      debugPrint('[bloc] save performance: nothing dirty');
      return;
    }
    if (state.committing) return;

    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save performance: no synced settings'));
      return;
    }

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitPerformance(performanceStaging);
    } catch (e) {
      debugPrint('[bloc] save performance failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'performance save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold or timeout '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'performance save failed: $e',
        );
      }
      return;
    }

    final nextSynced = synced.copyWith(
      performance: performanceStaging,
      clearError: true,
    );
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        performanceStaging: null,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
        actionLabelOf: state.actionLabelOf,
        buttonIdLabelOf: state.buttonIdLabelOf,
      ),
    );
    debugPrint('[bloc] save performance: synced');
    onSaveCompleted?.call();
  }

  /// User selected a button debounce value (chip).
  ///
  /// Stages the new wire index and marks dirty. Commit happens on Save.
  void _onDebounceRequested(
    DeviceSettingsButtonDebounceRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    if (synced.decodeErrors.contains('sensorOther')) {
      emit(state.copyWith(lastError: 'debounce unavailable: decode error'));
      return;
    }

    emit(
      state.copyWith(
        debounceStaging: event.wire,
        isDirty: true,
        clearError: true,
      ),
    );

    debugPrint('[bloc] debounce staged: wire=${event.wire}');
  }

  /// Save button debounce staging to device.
  Future<void> _onSaveDebounce(
    DeviceSettingsSaveButtonDebounceRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    final staging = state.debounceStaging;
    if (staging == null) {
      debugPrint('[bloc] save debounce: nothing dirty');
      return;
    }
    if (state.committing) return;

    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save debounce: no synced settings'));
      return;
    }

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitDebounce(staging);
    } catch (e) {
      debugPrint('[bloc] save debounce failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'debounce save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        onEscalationRequested?.call(
          'debounce save failed: $e',
        );
      }
      return;
    }

    final nextSynced = synced.copyWith(
      debounceMs: staging,
      debounceLabel: null,
      clearError: true,
    );
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        debounceStaging: null,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
        actionLabelOf: state.actionLabelOf,
        buttonIdLabelOf: state.buttonIdLabelOf,
      ),
    );
    debugPrint('[bloc] save debounce: synced');
    onSaveCompleted?.call();
  }

  /// User selected a sleep time value (chip).
  void _onSleepRequested(
    DeviceSettingsSleepTimeRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    if (synced.decodeErrors.contains('sensorOther')) {
      emit(state.copyWith(lastError: 'sleep time unavailable: decode error'));
      return;
    }

    emit(
      state.copyWith(sleepStaging: event.wire, isDirty: true, clearError: true),
    );

    debugPrint('[bloc] sleep time staged: wire=${event.wire}');
  }

  /// Save sleep time staging to device.
  Future<void> _onSaveSleep(
    DeviceSettingsSaveSleepTimeRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    final staging = state.sleepStaging;
    if (staging == null) {
      debugPrint('[bloc] save sleep time: nothing dirty');
      return;
    }
    if (state.committing) return;

    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save sleep time: no synced settings'));
      return;
    }

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitSleep(staging);
    } catch (e) {
      debugPrint('[bloc] save sleep time failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'sleep time save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        onEscalationRequested?.call(
          'sleep time save failed: $e',
        );
      }
      return;
    }

    final nextSynced = synced.copyWith(
      sleepSeconds: staging,
      sleepLabel: null,
      clearError: true,
    );
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        sleepStaging: null,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
        actionLabelOf: state.actionLabelOf,
        buttonIdLabelOf: state.buttonIdLabelOf,
      ),
    );
    debugPrint('[bloc] save sleep time: synced');
    onSaveCompleted?.call();
  }

  /// User toggled wheel direction invert.
  void _onWheelInvertRequested(
    DeviceSettingsWheelInvertRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }

    if (synced.decodeErrors.contains('sensorOther')) {
      emit(
        state.copyWith(lastError: 'wheel direction unavailable: decode error'),
      );
      return;
    }

    emit(
      state.copyWith(
        wheelInvertStaging: event.invert,
        isDirty: true,
        clearError: true,
      ),
    );

    debugPrint('[bloc] wheel invert staged: ${event.invert}');
  }

  /// Save wheel direction staging to device.
  Future<void> _onSaveWheelInvert(
    DeviceSettingsSaveWheelInvertRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    final staging = state.wheelInvertStaging;
    if (staging == null) {
      debugPrint('[bloc] save wheel direction: nothing dirty');
      return;
    }
    if (state.committing) return;

    final synced = state.synced;
    if (synced == null) {
      emit(
        state.copyWith(lastError: 'save wheel direction: no synced settings'),
      );
      return;
    }

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitWheelInvert(staging);
    } catch (e) {
      debugPrint('[bloc] save wheel direction failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'wheel direction save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        onEscalationRequested?.call(
          'wheel direction save failed: $e',
        );
      }
      return;
    }

    final nextSynced = synced.copyWith(wheelInvert: staging, clearError: true);
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        wheelInvertStaging: null,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
        actionLabelOf: state.actionLabelOf,
        buttonIdLabelOf: state.buttonIdLabelOf,
      ),
    );
    debugPrint('[bloc] save wheel direction: synced');
    onSaveCompleted?.call();
  }

  /// Commits every dirty Parameter Setting field in one D4 transaction.
  Future<void> _onSaveParameterSettings(
    DeviceSettingsSaveParameterSettingsRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    final synced = state.synced;
    final commit = commitParameterSettings;
    if (synced == null) {
      emit(state.copyWith(lastError: 'parameter save: no synced settings'));
      return;
    }
    if (state.committing || !state.hasAnyStaging) return;
    if (synced.decodeErrors.contains('sensorOther')) {
      emit(
        state.copyWith(lastError: 'parameter save: sensor block unavailable'),
      );
      return;
    }
    if (commit == null) {
      emit(state.copyWith(lastError: 'parameter save: commit is not wired'));
      return;
    }

    final patch = ParameterSettingsPatch(
      rippleEnabled: state.rippleControlStaging,
      angleSnapEnabled: state.angleSnapStaging,
      angleTuneEnabled: state.angleTuneEnabledStaging,
      angleTuneWire: state.angleTuneStaging,
      lodWire: state.lodStaging,
      performanceWire: state.performanceStaging,
      debounceWire: state.debounceStaging,
      sleepWire: state.sleepStaging,
      wheelInvert: state.wheelInvertStaging,
    );
    if (patch.isEmpty) return;

    emit(state.copyWith(committing: true, clearError: true));
    try {
      await commit(patch);
    } catch (e) {
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'parameter save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        onEscalationRequested?.call(
          'parameter settings save failed: $e',
        );
      }
      return;
    }

    final nextSynced = synced.copyWith(
      rippleOn: patch.rippleEnabled ?? synced.rippleOn,
      angleSnapOn: patch.angleSnapEnabled ?? synced.angleSnapOn,
      angleTuneOn: patch.angleTuneEnabled ?? synced.angleTuneOn,
      angleTune: patch.angleTuneWire ?? synced.angleTune,
      angleTuneLabel: patch.angleTuneWire == null
          ? synced.angleTuneLabel
          : const TranslationCodec().angleTuneWireToLabel(
              patch.angleTuneWire!,
              [
                for (final option
                    in synced.angleTuneOptions ?? const <AngleTuneOptionData>[])
                  AngleTuneOption(wire: option.wire, label: option.label),
              ],
            ),
      lodMm: patch.lodWire ?? synced.lodMm,
      performance: patch.performanceWire ?? synced.performance,
      debounceMs: patch.debounceWire ?? synced.debounceMs,
      sleepSeconds: patch.sleepWire ?? synced.sleepSeconds,
      wheelInvert: patch.wheelInvert ?? synced.wheelInvert,
      clearError: true,
    );
    emit(
      state.copyWith(
        synced: nextSynced,
        clearStaging: true,
        committing: false,
        consecutiveFailures: 0,
        clearError: true,
      ),
    );
    debugPrint('[bloc] save parameter settings: synced');
    onSaveCompleted?.call();
  }

  // --- RGB backlight (0xE2) staging handlers ---

  /// Guard: backlight editable only when synced, present, and not decode-locked.
  bool _backlightEditable(DeviceSettingsState synced) {
    if (!synced.hasRgbBacklight) return false;
    if (synced.decodeErrors.contains('rgbBacklight')) return false;
    return true;
  }

  void _onBacklightEnableRequested(
    DeviceSettingsBacklightEnableRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }
    if (!_backlightEditable(synced)) {
      emit(state.copyWith(lastError: 'backlight unavailable'));
      return;
    }
    emit(
      state.copyWith(
        rgbEnableStaging: event.enable,
        isDirty: true,
        clearError: true,
      ),
    );
    debugPrint('[bloc] backlight enable staged: ${event.enable}');
  }

  void _onBacklightModeRequested(
    DeviceSettingsBacklightModeRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }
    if (!_backlightEditable(synced)) {
      emit(state.copyWith(lastError: 'backlight unavailable'));
      return;
    }
    emit(
      state.copyWith(
        rgbModeIdStaging: event.modeId,
        isDirty: true,
        clearError: true,
      ),
    );
    debugPrint('[bloc] backlight mode staged: ${event.modeId}');
  }

  void _onBacklightColorRequested(
    DeviceSettingsBacklightColorRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }
    if (!_backlightEditable(synced)) {
      emit(state.copyWith(lastError: 'backlight unavailable'));
      return;
    }
    emit(
      state.copyWith(
        rgbRStaging: event.r,
        rgbGStaging: event.g,
        rgbBStaging: event.b,
        isDirty: true,
        clearError: true,
      ),
    );
    debugPrint(
      '[bloc] backlight color staged: '
      'r=${event.r} g=${event.g} b=${event.b}',
    );
  }

  void _onBacklightBrightnessRequested(
    DeviceSettingsBacklightBrightnessRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }
    if (!_backlightEditable(synced)) {
      emit(state.copyWith(lastError: 'backlight unavailable'));
      return;
    }
    emit(
      state.copyWith(
        rgbBrightnessStaging: event.level,
        isDirty: true,
        clearError: true,
      ),
    );
    debugPrint('[bloc] backlight brightness staged: ${event.level}');
  }

  void _onBacklightSpeedRequested(
    DeviceSettingsBacklightSpeedRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }
    if (!_backlightEditable(synced)) {
      emit(state.copyWith(lastError: 'backlight unavailable'));
      return;
    }
    emit(
      state.copyWith(
        rgbSpeedStaging: event.level,
        isDirty: true,
        clearError: true,
      ),
    );
    debugPrint('[bloc] backlight speed staged: ${event.level}');
  }

  void _onBacklightSleepRequested(
    DeviceSettingsBacklightSleepRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'no settings loaded'));
      return;
    }
    if (!_backlightEditable(synced)) {
      emit(state.copyWith(lastError: 'backlight unavailable'));
      return;
    }
    emit(
      state.copyWith(
        rgbSleepTimeStaging: event.wire,
        isDirty: true,
        clearError: true,
      ),
    );
    debugPrint('[bloc] backlight sleep staged: wire=${event.wire}');
  }

  /// Save all staged RGB backlight fields to the device (one 0xE2 SET).
  Future<void> _onSaveBacklight(
    DeviceSettingsSaveBacklightRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    final hasStaging =
        state.rgbEnableStaging != null ||
        state.rgbModeIdStaging != null ||
        state.rgbBrightnessStaging != null ||
        state.rgbSpeedStaging != null ||
        state.rgbRStaging != null ||
        state.rgbGStaging != null ||
        state.rgbBStaging != null ||
        state.rgbSleepTimeStaging != null;
    if (!hasStaging) {
      debugPrint('[bloc] save backlight: nothing dirty');
      return;
    }
    if (state.committing) return;

    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save backlight: no synced settings'));
      return;
    }
    if (!_backlightEditable(synced)) {
      emit(state.copyWith(lastError: 'save backlight: backlight unavailable'));
      return;
    }

    // Overlay staged values only for validation and the refreshed UI. The
    // actual E2 SET is a semantic patch: DeviceScope re-reads the live block
    // and L5 preserves every unedited byte, including unknown firmware data.
    final modeId = state.rgbModeIdStaging ?? synced.rgbModeId ?? 0;
    final brightness = state.rgbBrightnessStaging ?? synced.rgbBrightness ?? 0;
    final speed = state.rgbSpeedStaging ?? synced.rgbSpeed ?? 0;
    final r = state.rgbRStaging ?? synced.rgbR ?? 0;
    final g = state.rgbGStaging ?? synced.rgbG ?? 0;
    final b = state.rgbBStaging ?? synced.rgbB ?? 0;
    final sleepTime = state.rgbSleepTimeStaging ?? synced.rgbSleepTime ?? 0;

    // Validate only values the user staged against the active capability
    // schema (FR-OPS-003, FR-RGB-001/002/004). Values that arrived from the
    // device are preserved verbatim when the user changes another field: the
    // device may use a firmware-specific representation such as 0xFF for a
    // current speed value, which must not prevent an enable-only E2 update.
    final caps = activeCapabilities?.rgbBacklight;
    if (caps != null && caps.present) {
      if (state.rgbModeIdStaging != null &&
          caps.modes.isNotEmpty &&
          !caps.modes.any((m) => m.id == modeId)) {
        emit(
          state.copyWith(lastError: 'save backlight: unsupported mode $modeId'),
        );
        return;
      }
      if (state.rgbBrightnessStaging != null &&
          (brightness < 0 || brightness >= caps.brightnessLevels)) {
        emit(
          state.copyWith(
            lastError: 'save backlight: brightness $brightness out of range',
          ),
        );
        return;
      }
      if (state.rgbSpeedStaging != null &&
          (speed < 0 || speed >= caps.speedLevels)) {
        emit(
          state.copyWith(
            lastError: 'save backlight: speed $speed out of range',
          ),
        );
        return;
      }
      if (state.rgbSleepTimeStaging != null &&
          (sleepTime < 0 || sleepTime >= caps.sleepTimeOptions.length)) {
        emit(
          state.copyWith(
            lastError: 'save backlight: sleep index $sleepTime out of range',
          ),
        );
        return;
      }
    }

    final patch = RgbBacklightPatch(
      modeId: state.rgbModeIdStaging,
      brightness: state.rgbBrightnessStaging,
      speed: state.rgbSpeedStaging,
      red: state.rgbRStaging,
      green: state.rgbGStaging,
      blue: state.rgbBStaging,
      sleepWire: state.rgbSleepTimeStaging,
    );

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitRgbBacklight(patch);
    } catch (e) {
      debugPrint('[bloc] save backlight failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'backlight save failed: $e',
          consecutiveFailures: failures,
          clearStaging: true,
        ),
      );
      final isTimeout = e is TimeoutException || e.toString().contains('TimeoutException');
      if (failures >= failureEscalateThreshold || isTimeout) {
        onEscalationRequested?.call(
          'backlight save failed: $e',
        );
      }
      return;
    }

    // why: build next view via copyWith + clearStaging so unrelated sibling
    // staging is not silently dropped (see DPI remove/save race fix).
    final nextSynced = synced.copyWith(
      rgbEnable: state.rgbEnableStaging,
      rgbModeId: modeId,
      rgbModeLabel: const TranslationCodec().rgbModeToLabel(modeId),
      rgbBrightness: brightness,
      rgbBrightnessLabel: const TranslationCodec().brightnessLevelToLabel(
        brightness,
      ),
      rgbSpeed: speed,
      rgbSpeedLabel: const TranslationCodec().speedLevelToLabel(speed),
      rgbR: r,
      rgbG: g,
      rgbB: b,
      rgbSleepTime: sleepTime,
      rgbSleepLabel: const TranslationCodec().sleepIndexToLabel(sleepTime),
      clearError: true,
    );
    emit(
      state.copyWith(
        synced: nextSynced,
        committing: false,
        consecutiveFailures: 0,
        clearStaging: true,
        clearError: true,
      ),
    );
    debugPrint('[bloc] save backlight: synced');
    onSaveCompleted?.call();
  }

  static List<int> _hexToRgb(String hex) {
    final s = hex.replaceAll('#', '');
    if (s.length != 6) return [255, 255, 255];
    return [
      int.parse(s.substring(0, 2), radix: 16),
      int.parse(s.substring(2, 4), radix: 16),
      int.parse(s.substring(4, 6), radix: 16),
    ];
  }
}
