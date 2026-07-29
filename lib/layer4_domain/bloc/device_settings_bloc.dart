import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_state_view.dart';
import 'package:driver_hub/layer4_domain/button_mapping_reset.dart';
import 'package:driver_hub/layer4_domain/models/button_mapping_slot.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Domain → hardware commit. Implemented by [DeviceScope] only (L1→L5).
///
/// L3 must never supply this; L4 BLoC receives it from Scope factory.
typedef ButtonMappingCommit = Future<void> Function(
  List<ButtonMappingSlot> slots,
);

/// L4 domain controller — SDRD FR-OPS sandbox + L4 architecture chart.
///
/// Adjust → stage only (FR-OPS-001). Save → validate → commit (FR-OPS-003).
/// Cancel → wipe staging (FR-OPS-004). **No auto-write on adjust/reset.**
class DeviceSettingsBloc
    extends Bloc<DeviceSettingsEvent, DeviceSettingsViewState> {
  DeviceSettingsBloc({
    required this.commitButtonMapping,
    DeviceSettingsViewState? initial,
  }) : super(initial ?? DeviceSettingsViewState.empty) {
    on<DeviceSettingsHydrated>(_onHydrated);
    on<DeviceSettingsResetButtonMappingRequested>(_onResetButtonMapping);
    on<DeviceSettingsSaveRequested>(_onSave);
    on<DeviceSettingsCancelRequested>(_onCancel);
  }

  final ButtonMappingCommit commitButtonMapping;

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

  /// FR-OPS-001: stage only — no packets.
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

    emit(
      state.copyWith(
        buttonMappingStaging: staged,
        isDirty: true,
        clearError: true,
      ),
    );
  }

  /// FR-OPS-003: validate → commit via Scope (L1/L5).
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
          '(chart escalate to L1 — not wired)',
        );
      }
      return;
    }

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

  /// FR-OPS-004: wipe staging → last synchronized.
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
    List<ButtonMappingSlot> staging,
  ) {
    if (staging.length != 6) {
      return 'button mapping length invalid';
    }
    return null;
  }
}
