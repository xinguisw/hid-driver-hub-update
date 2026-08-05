import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_state_view.dart';
import 'package:driver_hub/layer4_domain/button_mapping_reset.dart';
import 'package:driver_hub/layer4_domain/button_mapping_validate.dart';
import 'package:driver_hub/layer4_domain/models/button_mapping_slot.dart';
import 'package:driver_hub/layer5_codec/button_action_catalog_map.dart';
import 'package:driver_hub/layer5_codec/codecs/translation_codec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef ButtonMappingCommit =
    Future<void> Function(List<ButtonMappingSlot> slots);

typedef ReportRateCommit = Future<void> Function(int reportRateHz);

typedef DpiLevelCommit = Future<void> Function(int dpiLevel);

typedef SensorTuningCommit = Future<void> Function(
  bool rippleControl,
  bool angleSnap,
);

typedef AngleTuneCommit = Future<void> Function(int wireValue);

typedef LodCommit = Future<void> Function(int wire);

typedef PerformanceCommit = Future<void> Function(int wire);

typedef OtherFeatureCommit = Future<void> Function(int wire);

typedef WheelInvertCommit = Future<void> Function(bool invert);

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
    required this.commitSensorTuning,
    required this.commitAngleTune,
    required this.commitLod,
    required this.commitPerformance,
    required this.commitDebounce,
    required this.commitSleep,
    required this.commitWheelInvert,
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
  }

  final ButtonMappingCommit commitButtonMapping;
  final ReportRateCommit commitReportRate;
  final DpiLevelCommit commitDpiLevel;
  final SensorTuningCommit commitSensorTuning;
  final AngleTuneCommit commitAngleTune;
  final LodCommit commitLod;
  final PerformanceCommit commitPerformance;
  final OtherFeatureCommit commitDebounce;
  final OtherFeatureCommit commitSleep;
  final WheelInvertCommit commitWheelInvert;
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
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        dpiCurrentLevelStaging: null,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
        actionLabelOf: state.actionLabelOf,
        buttonIdLabelOf: state.buttonIdLabelOf,
      ),
    );
    debugPrint('[bloc] save DPI level: synced');
    onSaveCompleted?.call();
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
}
