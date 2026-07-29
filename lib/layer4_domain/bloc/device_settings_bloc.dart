import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_state_view.dart';
import 'package:driver_hub/layer4_domain/button_mapping_reset.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Writes staged button map through L1 → L5 (Save path only).
typedef ButtonMappingCommit = Future<void> Function(
  List<ButtonMappingEntry> buttons,
);

/// L4 domain controller — official sandbox staging chart.
///
/// Flow: **Dispatch event** → **Sandbox staging** (no L5) → Cancel wipe /
/// Save validate → payload → [commitButtonMapping] (L1/L5).
class DeviceSettingsBloc
    extends Bloc<DeviceSettingsEvent, DeviceSettingsViewState> {
  DeviceSettingsBloc({
    required ButtonMappingCommit this.commitButtonMapping,
    DeviceSettingsViewState? initial,
    this.autoSaveAfterReset = true,
  }) : super(initial ?? DeviceSettingsViewState.empty) {
    on<DeviceSettingsHydrated>(_onHydrated);
    on<DeviceSettingsResetButtonMappingRequested>(_onResetButtonMapping);
    on<DeviceSettingsSaveRequested>(_onSave);
    on<DeviceSettingsCancelRequested>(_onCancel);
  }

  /// L1/L5 write hook — only invoked from Save handler.
  final ButtonMappingCommit commitButtonMapping;

  /// Until a Save button exists: after reset staging, enqueue Save (same chart
  /// Save nodes, still via [DeviceSettingsSaveRequested] — not a silent L5 call
  /// from the Reset handler body).
  final bool autoSaveAfterReset;

  /// Chart error-tracking threshold (escalate to L1 later).
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

  /// Chart: User adjusts → Dispatch already done → store sandbox (no L5/L6).
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

    final staged = stageButtonMappingDefaults(synced.buttons);
    debugPrint(
      '[bloc] reset buttonMapping staged '
      '${[
        for (var i = 0; i < staged.length; i++)
          'B${i + 1}=0x${staged[i].action.toRadixString(16)}'
      ].join(' ')}',
    );

    // Sandbox only — L3 paints displaySettings immediately (isDirty).
    emit(
      state.copyWith(
        buttonMappingStaging: staged,
        isDirty: true,
        clearError: true,
      ),
    );

    // Product: no Save UI yet → internal Save event (chart Save diamond path).
    if (autoSaveAfterReset) {
      add(const DeviceSettingsSaveRequested());
    }
  }

  /// Chart: Click save? Yes → validate → L2 caps → payload → Encoder L5.
  Future<void> _onSave(
    DeviceSettingsSaveRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) async {
    if (!state.isDirty || state.buttonMappingStaging == null) {
      debugPrint('[bloc] save: nothing dirty');
      return;
    }
    if (state.committing) return;

    final staging = List<ButtonMappingEntry>.from(state.buttonMappingStaging!);
    final synced = state.synced;
    if (synced == null) {
      emit(state.copyWith(lastError: 'save: no synced settings'));
      return;
    }

    // Validate staging buffer (limits).
    if (staging.length != 6) {
      emit(
        state.copyWith(
          lastError: 'button mapping: expected 6 slots, got ${staging.length}',
        ),
      );
      return;
    }

    final capsErr = _validateButtonMappingAgainstCaps(synced, staging);
    if (capsErr != null) {
      emit(state.copyWith(lastError: capsErr));
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
          '(chart: escalate to L1 — not wired)',
        );
      }
      return;
    }

    // Success: clear dirty; staging becomes last synchronized.
    final nextSynced = packButtonsOntoSettings(synced, staging);
    emit(
      DeviceSettingsViewState(
        synced: nextSynced,
        buttonMappingStaging: null,
        isDirty: false,
        committing: false,
        consecutiveFailures: 0,
        lastError: null,
      ),
    );
    debugPrint('[bloc] save buttonMapping: synced');
  }

  /// Chart: Click cancel? → wipe staging → last synchronized.
  void _onCancel(
    DeviceSettingsCancelRequested event,
    Emitter<DeviceSettingsViewState> emit,
  ) {
    if (!state.isDirty && state.buttonMappingStaging == null) return;
    emit(
      state.copyWith(
        clearStaging: true,
        clearError: true,
        committing: false,
      ),
    );
    debugPrint('[bloc] cancel: staging wiped');
  }

  String? _validateButtonMappingAgainstCaps(
    DeviceSettingsState synced,
    List<ButtonMappingEntry> staging,
  ) {
    if (staging.length != 6) {
      return 'button mapping length invalid';
    }
    // L2 presence already filtered at stage (echo non-remappable).
    return null;
  }
}
