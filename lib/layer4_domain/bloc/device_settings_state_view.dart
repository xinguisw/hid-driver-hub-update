import 'package:driver_hub/layer4_domain/models/button_mapping_slot.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';

/// Labels for staged/synced button rows (injected; no L5 import here).
typedef ButtonActionLabelFn = String Function(
  int action,
  int param1,
  int param2,
  int param3,
);
typedef ButtonIdLabelFn = String Function(int buttonId);

/// Synced profile + button-map sandbox for one device settings session.
class DeviceSettingsViewState {
  const DeviceSettingsViewState({
    this.synced,
    this.buttonMappingStaging,
    this.reportRateStaging,
    this.dpiCurrentLevelStaging,
    this.rippleControlStaging,
    this.angleSnapStaging,
    this.angleTuneStaging,
    this.angleTuneLabelStaging,
    this.angleTuneEnabledStaging,
    this.lodStaging,
    this.performanceStaging,
    this.isDirty = false,
    this.committing = false,
    this.consecutiveFailures = 0,
    this.lastError,
    this.actionLabelOf,
    this.buttonIdLabelOf,
  });

  final DeviceSettingsState? synced;
  final List<ButtonMappingSlot>? buttonMappingStaging;
  final int? reportRateStaging;
  final int? dpiCurrentLevelStaging;
  final bool? rippleControlStaging;
  final bool? angleSnapStaging;
  final int? angleTuneStaging;
  final String? angleTuneLabelStaging;
  final bool? angleTuneEnabledStaging;
  final int? lodStaging;
  final int? performanceStaging;
  final bool isDirty;
  final bool committing;
  final int consecutiveFailures;
  final String? lastError;

  final ButtonActionLabelFn? actionLabelOf;
  final ButtonIdLabelFn? buttonIdLabelOf;

  DeviceSettingsState? get displaySettings {
    final base = synced;
    if (base == null) return null;
    final staging = buttonMappingStaging;
    if (!isDirty || staging == null) return base;
    return packButtonsOntoSettings(
      base,
      staging,
      actionLabelOf: actionLabelOf,
      buttonIdLabelOf: buttonIdLabelOf,
    );
  }

  static const empty = DeviceSettingsViewState();

  DeviceSettingsViewState copyWith({
    DeviceSettingsState? synced,
    List<ButtonMappingSlot>? buttonMappingStaging,
    int? reportRateStaging,
    int? dpiCurrentLevelStaging,
    bool? rippleControlStaging,
    bool? angleSnapStaging,
    int? angleTuneStaging,
    String? angleTuneLabelStaging,
    bool? angleTuneEnabledStaging,
    int? lodStaging,
    int? performanceStaging,
    bool? isDirty,
    bool? committing,
    int? consecutiveFailures,
    String? lastError,
    ButtonActionLabelFn? actionLabelOf,
    ButtonIdLabelFn? buttonIdLabelOf,
    bool clearStaging = false,
    bool clearError = false,
  }) {
    return DeviceSettingsViewState(
      synced: synced ?? this.synced,
      buttonMappingStaging: clearStaging
          ? null
          : (buttonMappingStaging ?? this.buttonMappingStaging),
      reportRateStaging: clearStaging
          ? null
          : (reportRateStaging ?? this.reportRateStaging),
      dpiCurrentLevelStaging: clearStaging
          ? null
          : (dpiCurrentLevelStaging ?? this.dpiCurrentLevelStaging),
      rippleControlStaging: clearStaging
          ? null
          : (rippleControlStaging ?? this.rippleControlStaging),
      angleSnapStaging: clearStaging
          ? null
          : (angleSnapStaging ?? this.angleSnapStaging),
      angleTuneStaging: clearStaging
          ? null
          : (angleTuneStaging ?? this.angleTuneStaging),
      angleTuneLabelStaging: clearStaging
          ? null
          : (angleTuneLabelStaging ?? this.angleTuneLabelStaging),
      angleTuneEnabledStaging: clearStaging
          ? null
          : (angleTuneEnabledStaging ?? this.angleTuneEnabledStaging),
      lodStaging: clearStaging
          ? null
          : (lodStaging ?? this.lodStaging),
      performanceStaging: clearStaging
          ? null
          : (performanceStaging ?? this.performanceStaging),
      isDirty: clearStaging ? false : (isDirty ?? this.isDirty),
      committing: committing ?? this.committing,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      lastError: clearError ? null : (lastError ?? this.lastError),
      actionLabelOf: actionLabelOf ?? this.actionLabelOf,
      buttonIdLabelOf: buttonIdLabelOf ?? this.buttonIdLabelOf,
    );
  }
}

DeviceSettingsState packButtonsOntoSettings(
  DeviceSettingsState base,
  List<ButtonMappingSlot> staging, {
  ButtonActionLabelFn? actionLabelOf,
  ButtonIdLabelFn? buttonIdLabelOf,
}) {
  final baseButtons = base.buttons;
  String labelForAction(ButtonMappingSlot s) {
    if (actionLabelOf != null) {
      return actionLabelOf(s.action, s.param1, s.param2, s.param3);
    }
    return '0x${s.action.toRadixString(16)}';
  }

  String labelForId(int id, ButtonData? baseRow) {
    if (baseRow?.buttonLabel != null) return baseRow!.buttonLabel!;
    if (buttonIdLabelOf != null) return buttonIdLabelOf(id);
    return 'Button $id';
  }

  final live = [
    for (var i = 0; i < staging.length; i++)
      ButtonData(
        id: i + 1,
        labelKey: baseButtons != null && i < baseButtons.length
            ? baseButtons[i].labelKey
            : 'button.${i + 1}',
        remappable: baseButtons != null && i < baseButtons.length
            ? baseButtons[i].remappable
            : true,
        hotspotX: baseButtons != null && i < baseButtons.length
            ? baseButtons[i].hotspotX
            : null,
        hotspotY: baseButtons != null && i < baseButtons.length
            ? baseButtons[i].hotspotY
            : null,
        hotspotR: baseButtons != null && i < baseButtons.length
            ? baseButtons[i].hotspotR
            : null,
        buttonLabel: labelForId(
          i + 1,
          baseButtons != null && i < baseButtons.length ? baseButtons[i] : null,
        ),
        actionLabel: labelForAction(staging[i]),
        action: staging[i].action,
        param1: staging[i].param1,
        param2: staging[i].param2,
        param3: staging[i].param3,
      ),
  ];
  return base.copyWith(
    buttonCount: live.length,
    buttons: live,
    clearError: true,
  );
}
