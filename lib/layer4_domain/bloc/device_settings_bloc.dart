import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_state_view.dart';
import 'package:driver_hub/layer4_domain/button_mapping_reset.dart';
import 'package:driver_hub/layer4_domain/button_mapping_validate.dart';
import 'package:driver_hub/layer4_domain/models/button_mapping_slot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef ButtonMappingCommit = Future<void> Function(
  List<ButtonMappingSlot> slots,
);

class DeviceSettingsBloc
    extends Bloc<DeviceSettingsEvent, DeviceSettingsViewState> {
  DeviceSettingsBloc({
    required this.commitButtonMapping,
    ButtonActionLabelFn? actionLabelOf,
    ButtonIdLabelFn? buttonIdLabelOf,
    DeviceSettingsViewState? initial,
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
          '[bloc] consecutiveFailures=$failures >= $failureEscalateThreshold',
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
  }

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
}
