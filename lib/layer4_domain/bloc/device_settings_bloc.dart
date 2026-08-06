import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_state_view.dart';
import 'package:driver_hub/layer4_domain/button_mapping_reset.dart';
import 'package:driver_hub/layer4_domain/button_mapping_validate.dart';
import 'package:driver_hub/layer4_domain/models/button_mapping_slot.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer5_codec/button_action_catalog_map.dart';
import 'package:driver_hub/layer5_codec/codecs/translation_codec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef ButtonMappingCommit =
    Future<void> Function(List<ButtonMappingSlot> slots);

typedef ReportRateCommit = Future<void> Function(int reportRateHz);

typedef DpiLevelCommit = Future<void> Function(int dpiLevel);

typedef DpiValuesCommit = Future<void> Function(Map<int, int> levelValues);

typedef DpiStagesCommit = Future<void> Function(
  List<DpiStageData> stagedLevels,
  int activeCount,
);

typedef SensorTuningCommit = Future<void> Function(
  bool rippleControl,
  bool angleSnap,
);

typedef AngleTuneCommit = Future<void> Function(int wireValue);

typedef LodCommit = Future<void> Function(int wire);

typedef PerformanceCommit = Future<void> Function(int wire);

typedef OtherFeatureCommit = Future<void> Function(int wire);

typedef WheelInvertCommit = Future<void> Function(bool invert);

/// Staged RGB backlight fields for one 0xE2 SET (FR-RGB-001..004).
///
/// Carried by [RgbBacklightCommit]; L4 builds this from staged values overlaid
/// on the last-synced block, and DeviceScope (L1) encodes the 8-byte wire block.
/// brightness/speed are level indices; sleepTime is a catalog option index.
typedef StagedRgbBacklight = ({
  bool enable,
  int modeId,
  int brightness,
  int speed,
  int r,
  int g,
  int b,
  int sleepTime,
});

typedef RgbBacklightCommit = Future<void> Function(StagedRgbBacklight values);

/// FR-ARC-014c: escalation callback invoked when consecutive failures reach threshold.
///
/// L1 [DeviceScope] provides this to force session teardown/reconnect.
typedef EscalationCallback = void Function(String reason);

/// Save completed callback — UI uses this to dismiss sidebar.
typedef SaveCompletedCallback = void Function();

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
    required this.commitDpiStages,
    required this.commitSensorTuning,
    required this.commitAngleTune,
    required this.commitLod,
    required this.commitPerformance,
    required this.commitDebounce,
    required this.commitSleep,
    required this.commitWheelInvert,
    required this.commitRgbBacklight,
    ButtonActionLabelFn? actionLabelOf,
    ButtonIdLabelFn? buttonIdLabelOf,
    DeviceSettingsViewState? initial,
    this.capabilities,
    this.capabilitiesLookup,
    this.onEscalationRequested,
    this.onSaveCompleted,
  }) : super(
         (initial ?? DeviceSettingsViewState.empty).copyWith(
           actionLabelOf: actionLabelOf,
           buttonIdLabelOf: buttonIdLabelOf,
         ),
       ) {
    on<DeviceSettingsHydrated>(_onHydrated);
    on<DeviceSettingsResetButtonMappingRequested>(_onResetButtonMapping);
    on<DeviceSettingsSaveRequested>(_onSave);
    on<DeviceSettingsCancelRequested>(_onCancel);
    on<DeviceSettingsNavigationRequested>(_onNavigationRequested);
    on<DeviceSettingsButtonMappingSlotRequested>(_onButtonMappingSlotRequested);
    on<DeviceSettingsSpecialComboRequested>(_onSpecialComboRequested);
    on<DeviceSettingsReportRateRequested>(_onReportRateRequested);
    on<DeviceSettingsSaveReportRateRequested>(_onSaveReportRate);
    on<DeviceSettingsDpiLevelRequested>(_onDpiLevelRequested);
    on<DeviceSettingsSaveDpiLevelRequested>(_onSaveDpiLevel);
    on<DeviceSettingsDpiValueRequested>(_onDpiValueRequested);
    on<DeviceSettingsSaveDpiValuesRequested>(_onSaveDpiValues);
    on<DeviceSettingsDpiStageAddRequested>(_onDpiStageAddRequested);
    on<DeviceSettingsDpiStageRemoveRequested>(_onDpiStageRemoveRequested);
    on<DeviceSettingsSaveDpiStagesRequested>(_onSaveDpiStages);
    on<DeviceSettingsRippleControlRequested>(_onRippleControlRequested);
    on<DeviceSettingsAngleSnapRequested>(_onAngleSnapRequested);
    on<DeviceSettingsSaveSensorTuningRequested>(_onSaveSensorTuning);
    on<DeviceSettingsAngleTuneToggled>(_onAngleTuneToggled);
    on<DeviceSettingsAngleTuneValueChanged>(_onAngleTuneValueChanged);
    on<DeviceSettingsSaveAngleTuneRequested>(_onSaveAngleTune);
    on<DeviceSettingsLodRequested>(_onLodRequested);
    on<DeviceSettingsSaveLodRequested>(_onSaveLod);
    on<DeviceSettingsPerformanceRequested>(_onPerformanceRequested);
    on<DeviceSettingsSavePerformanceRequested>(_onSavePerformance);
    on<DeviceSettingsButtonDebounceRequested>(_onDebounceRequested);
    on<DeviceSettingsSaveButtonDebounceRequested>(_onSaveDebounce);
    on<DeviceSettingsSleepTimeRequested>(_onSleepRequested);
    on<DeviceSettingsSaveSleepTimeRequested>(_onSaveSleep);
    on<DeviceSettingsWheelInvertRequested>(_onWheelInvertRequested);
    on<DeviceSettingsSaveWheelInvertRequested>(_onSaveWheelInvert);
    on<DeviceSettingsBacklightEnableRequested>(_onBacklightEnableRequested);
    on<DeviceSettingsBacklightModeRequested>(_onBacklightModeRequested);
    on<DeviceSettingsBacklightColorRequested>(_onBacklightColorRequested);
    on<DeviceSettingsBacklightBrightnessRequested>(
      _onBacklightBrightnessRequested,
    );
    on<DeviceSettingsBacklightSpeedRequested>(_onBacklightSpeedRequested);
    on<DeviceSettingsBacklightSleepRequested>(_onBacklightSleepRequested);
    on<DeviceSettingsSaveBacklightRequested>(_onSaveBacklight);
  }

  final ButtonMappingCommit commitButtonMapping;
  final ReportRateCommit commitReportRate;
  final DpiLevelCommit commitDpiLevel;
  final DpiValuesCommit commitDpiValues;
  final DpiStagesCommit commitDpiStages;
  final SensorTuningCommit commitSensorTuning;
  final AngleTuneCommit commitAngleTune;
  final LodCommit commitLod;
  final PerformanceCommit commitPerformance;
  final OtherFeatureCommit commitDebounce;
  final OtherFeatureCommit commitSleep;
  final WheelInvertCommit commitWheelInvert;
  final RgbBacklightCommit commitRgbBacklight;
  final DeviceCapabilities? capabilities;
  final CapabilitiesLookup? capabilitiesLookup;
  final EscalationCallback? onEscalationRequested;

  /// Caps in force right now: the constructor value wins, else the late lookup.
  DeviceCapabilities? get activeCapabilities =>
      capabilities ?? capabilitiesLookup?.call();
  final SaveCompletedCallback? onSaveCompleted;

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
      if (failures >= failureEscalateThreshold) {
        onEscalationRequested?.call(
          'reset buttonMapping failed $failures consecutive times',
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
        ),
      );
      if (failures >= failureEscalateThreshold) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'button mapping save failed $failures consecutive times',
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
    if (!state.isDirty && state.buttonMappingStaging == null) return;
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
    if (!state.isDirty && state.buttonMappingStaging == null) return;
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
      emit(state.copyWith(lastError: 'button mapping unavailable: decode error'));
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
      emit(state.copyWith(lastError: 'button mapping unavailable: decode error'));
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
        ),
      );
      if (failures >= failureEscalateThreshold) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'report rate save failed $failures consecutive times',
        );
      }
      return;
    }

    final nextSynced = synced.copyWith(
      reportRateHz: staging,
      clearError: true,
    );
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
            lastError: 'DPI level ${event.level} not in capabilities $validLevels',
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
        ),
      );
      if (failures >= failureEscalateThreshold) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'DPI level save failed $failures consecutive times',
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
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
      ),
    );
    debugPrint('[bloc] save DPI level: synced');
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
      state.copyWith(
        dpiValueStaging: next,
        isDirty: true,
        clearError: true,
      ),
    );

    debugPrint('[bloc] DPI value staged: level=${event.level} value=$snapped');
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
        ),
      );
      if (failures >= failureEscalateThreshold) {
        onEscalationRequested?.call(
          'DPI values save failed $failures consecutive times',
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
    final nextSynced = synced.copyWith(
      dpiLevels: levels,
      clearError: true,
    );
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
    levels.add(DpiStageData(
      level: newLevel,
      value: defaultDpi,
      color: defaultColor,
    ));
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
      reindexed.add(DpiStageData(
        level: i + 1,
        value: removed[i].value,
        color: removed[i].color,
      ));
    }
    emit(
      state.copyWith(
        dpiStageRemoveLevelStaging: event.level,
        dpiStageLevelsStaging: reindexed,
        isDirty: true,
        clearError: true,
      ),
    );
    debugPrint('[bloc] DPI stage remove staged: level=${event.level}');
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
    } catch (e) {
      debugPrint('[bloc] save DPI stages failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          dpiStageSaveInFlight: false,
          lastError: 'DPI stages save failed: $e',
          consecutiveFailures: failures,
        ),
      );
      if (failures >= failureEscalateThreshold) {
        onEscalationRequested?.call(
          'DPI stages save failed $failures consecutive times',
        );
      }
      return;
    }

    // why: the staged list IS the post-add/remove result; its length is the
    // authoritative new count (handles multiple adds, single/multi removes).
    final count = stagedLevels.length;
    final nextSynced = synced.copyWith(
      dpiActiveLevelCount: count,
      dpiLevels: stagedLevels,
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
        ),
      );
      if (failures >= failureEscalateThreshold) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'sensor tuning save failed $failures consecutive times',
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
    final label = translate.angleTuneWireToLabel(
      event.wireValue,
      synced.angleTuneOptions ?? const <AngleTuneOption>[],
    );

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
    if (angleTuneStaging == null) {
      debugPrint('[bloc] save angle tune: nothing dirty');
      return;
    }
    if (state.committing) return;

    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save angle tune: no synced settings'));
      return;
    }

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitAngleTune(angleTuneStaging);
    } catch (e) {
      debugPrint('[bloc] save angle tune failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'angle tune save failed: $e',
          consecutiveFailures: failures,
        ),
      );
      if (failures >= failureEscalateThreshold) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'angle tune save failed $failures consecutive times',
        );
      }
      return;
    }

    final nextSynced = synced.copyWith(
      angleTune: angleTuneStaging,
      angleTuneLabel: null, // will be recomputed from wire value on next GET
      clearError: true,
    );
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        angleTuneStaging: null,
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
      state.copyWith(
        lodStaging: event.wire,
        isDirty: true,
        clearError: true,
      ),
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
        ),
      );
      if (failures >= failureEscalateThreshold) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'LOD save failed $failures consecutive times',
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
        ),
      );
      if (failures >= failureEscalateThreshold) {
        debugPrint(
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold '
          '— escalating to L1 watcher',
        );
        onEscalationRequested?.call(
          'performance save failed $failures consecutive times',
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
        ),
      );
      if (failures >= failureEscalateThreshold) {
        onEscalationRequested?.call(
          'debounce save failed $failures consecutive times',
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
      state.copyWith(
        sleepStaging: event.wire,
        isDirty: true,
        clearError: true,
      ),
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
        ),
      );
      if (failures >= failureEscalateThreshold) {
        onEscalationRequested?.call(
          'sleep time save failed $failures consecutive times',
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
      emit(state.copyWith(lastError: 'save wheel direction: no synced settings'));
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
        ),
      );
      if (failures >= failureEscalateThreshold) {
        onEscalationRequested?.call(
          'wheel direction save failed $failures consecutive times',
        );
      }
      return;
    }

    final nextSynced = synced.copyWith(
      wheelInvert: staging,
      clearError: true,
    );
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
    final hasStaging = state.rgbEnableStaging != null ||
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

    // Overlay staged values on the last-synced block (single 0xE2 SET).
    final enable = state.rgbEnableStaging ?? synced.rgbEnable ?? false;
    final modeId = state.rgbModeIdStaging ?? synced.rgbModeId ?? 0;
    final brightness = state.rgbBrightnessStaging ?? synced.rgbBrightness ?? 0;
    final speed = state.rgbSpeedStaging ?? synced.rgbSpeed ?? 0;
    final r = state.rgbRStaging ?? synced.rgbR ?? 0;
    final g = state.rgbGStaging ?? synced.rgbG ?? 0;
    final b = state.rgbBStaging ?? synced.rgbB ?? 0;
    final sleepTime = state.rgbSleepTimeStaging ?? synced.rgbSleepTime ?? 0;

    // Validate against the active device's capability schema (FR-OPS-003,
    // FR-RGB-001/002/004): never send an out-of-range or unsupported value.
    final caps = activeCapabilities?.rgbBacklight;
    if (caps != null && caps.present) {
      if (caps.modes.isNotEmpty &&
          !caps.modes.any((m) => m.id == modeId)) {
        emit(state.copyWith(lastError: 'save backlight: unsupported mode $modeId'));
        return;
      }
      if (brightness < 0 || brightness >= caps.brightnessLevels) {
        emit(
          state.copyWith(
            lastError: 'save backlight: brightness $brightness out of range',
          ),
        );
        return;
      }
      if (speed < 0 || speed >= caps.speedLevels) {
        emit(
          state.copyWith(lastError: 'save backlight: speed $speed out of range'),
        );
        return;
      }
      if (sleepTime < 0 || sleepTime >= caps.sleepTimeOptions.length) {
        emit(
          state.copyWith(
            lastError: 'save backlight: sleep index $sleepTime out of range',
          ),
        );
        return;
      }
    }

    final staged = (
      enable: enable,
      modeId: modeId,
      brightness: brightness,
      speed: speed,
      r: r,
      g: g,
      b: b,
      sleepTime: sleepTime,
    );

    emit(state.copyWith(committing: true, clearError: true));

    try {
      await commitRgbBacklight(staged);
    } catch (e) {
      debugPrint('[bloc] save backlight failed: $e');
      final failures = state.consecutiveFailures + 1;
      emit(
        state.copyWith(
          committing: false,
          lastError: 'backlight save failed: $e',
          consecutiveFailures: failures,
        ),
      );
      if (failures >= failureEscalateThreshold) {
        onEscalationRequested?.call(
          'backlight save failed $failures consecutive times',
        );
      }
      return;
    }

    // why: build next view via copyWith + clearStaging so unrelated sibling
    // staging is not silently dropped (see DPI remove/save race fix).
    final nextSynced = synced.copyWith(
      rgbEnable: enable,
      rgbModeId: modeId,
      rgbModeLabel: const TranslationCodec().rgbModeToLabel(modeId),
      rgbBrightness: brightness,
      rgbBrightnessLabel:
          const TranslationCodec().brightnessLevelToLabel(brightness),
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
}
