import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_state_view.dart';
import 'package:driver_hub/layer4_domain/button_mapping_reset.dart';
import 'package:driver_hub/layer4_domain/button_mapping_validate.dart';
import 'package:driver_hub/layer4_domain/models/button_mapping_slot.dart';
import 'package:driver_hub/layer5_codec/button_action_catalog_map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef ButtonMappingCommit =
    Future<void> Function(List<ButtonMappingSlot> slots);

typedef ReportRateCommit = Future<void> Function(int reportRateHz);

/// FR-ARC-014c: escalation callback invoked when consecutive failures reach threshold.
///
/// L1 [DeviceScope] provides this to force session teardown/reconnect.
typedef EscalationCallback = void Function(String reason);

/// Save completed callback — UI uses this to dismiss sidebar.
typedef SaveCompletedCallback = void Function();

class DeviceSettingsBloc
    extends Bloc<DeviceSettingsEvent, DeviceSettingsViewState> {
  DeviceSettingsBloc({
    required this.commitButtonMapping,
    required this.commitReportRate,
    ButtonActionLabelFn? actionLabelOf,
    ButtonIdLabelFn? buttonIdLabelOf,
    DeviceSettingsViewState? initial,
    this.capabilities,
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
  }

  final ButtonMappingCommit commitButtonMapping;
  final ReportRateCommit commitReportRate;
  final DeviceCapabilities? capabilities;
  final EscalationCallback? onEscalationRequested;
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
      capabilities: capabilities,
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
      capabilities: capabilities,
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
}
