import 'package:driver_hub/layer5_codec/button_mapping_slot.dart';
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
    this.dpiValueStaging,
    this.dpiStageAddStaging = false,
    this.dpiStageRemoveLevelStaging,
    this.dpiStageLevelsStaging,
    this.dpiStageSaveInFlight = false,
    this.rippleControlStaging,
    this.angleSnapStaging,
    this.angleTuneStaging,
    this.angleTuneLabelStaging,
    this.angleTuneEnabledStaging,
    this.lodStaging,
    this.performanceStaging,
    this.debounceStaging,
    this.sleepStaging,
    this.wheelInvertStaging,
    this.rgbEnableStaging,
    this.rgbModeIdStaging,
    this.rgbBrightnessStaging,
    this.rgbSpeedStaging,
    this.rgbRStaging,
    this.rgbGStaging,
    this.rgbBStaging,
    this.rgbSleepTimeStaging,
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

  /// Staged DPI value per level (1-based level → value); null = no change.
  final Map<int, int>? dpiValueStaging;

  /// True when a `+` add-stage is staged, pending Save.
  final bool dpiStageAddStaging;

  /// 1-based level staged for removal (null = none).
  final int? dpiStageRemoveLevelStaging;

  /// The modified DPI level list (add/remove rearrange) staged for preview.
  final List<DpiStageData>? dpiStageLevelsStaging;

  /// True while a DPI stage add/remove save is in flight (per-concern guard,
  /// independent of the shared [committing] flag).
  final bool dpiStageSaveInFlight;

  final bool? rippleControlStaging;
  final bool? angleSnapStaging;
  final int? angleTuneStaging;
  final String? angleTuneLabelStaging;
  final bool? angleTuneEnabledStaging;
  final int? lodStaging;
  final int? performanceStaging;
  final int? debounceStaging;
  final int? sleepStaging;
  final bool? wheelInvertStaging;

  /// Staged RGB backlight fields (0xE2). Each null = unchanged from synced.
  /// brightness/speed are level indices; rgbSleepTime is an index into the
  /// catalog's `sleepTimeOptions`.
  final bool? rgbEnableStaging;
  final int? rgbModeIdStaging;
  final int? rgbBrightnessStaging;
  final int? rgbSpeedStaging;
  final int? rgbRStaging;
  final int? rgbGStaging;
  final int? rgbBStaging;
  final int? rgbSleepTimeStaging;
  final bool isDirty;
  final bool committing;
  final int consecutiveFailures;
  final String? lastError;

  final ButtonActionLabelFn? actionLabelOf;
  final ButtonIdLabelFn? buttonIdLabelOf;

  // --- Merged RGB backlight values (staged over synced) for live preview ---
  bool? get displayRgbEnable => rgbEnableStaging ?? synced?.rgbEnable;
  int? get displayRgbModeId => rgbModeIdStaging ?? synced?.rgbModeId;
  int? get displayRgbBrightness => rgbBrightnessStaging ?? synced?.rgbBrightness;
  int? get displayRgbSpeed => rgbSpeedStaging ?? synced?.rgbSpeed;
  int? get displayRgbR => rgbRStaging ?? synced?.rgbR;
  int? get displayRgbG => rgbGStaging ?? synced?.rgbG;
  int? get displayRgbB => rgbBStaging ?? synced?.rgbB;
  int? get displayRgbSleepTime => rgbSleepTimeStaging ?? synced?.rgbSleepTime;

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
    Map<int, int>? dpiValueStaging,
    bool? dpiStageAddStaging,
    int? dpiStageRemoveLevelStaging,
    List<DpiStageData>? dpiStageLevelsStaging,
    bool? dpiStageSaveInFlight,
    bool? rippleControlStaging,
    bool? angleSnapStaging,
    int? angleTuneStaging,
    String? angleTuneLabelStaging,
    bool? angleTuneEnabledStaging,
    int? lodStaging,
    int? performanceStaging,
    int? debounceStaging,
    int? sleepStaging,
    bool? wheelInvertStaging,
    bool? rgbEnableStaging,
    int? rgbModeIdStaging,
    int? rgbBrightnessStaging,
    int? rgbSpeedStaging,
    int? rgbRStaging,
    int? rgbGStaging,
    int? rgbBStaging,
    int? rgbSleepTimeStaging,
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
      dpiValueStaging: clearStaging
          ? null
          : (dpiValueStaging ?? this.dpiValueStaging),
      dpiStageAddStaging: clearStaging
          ? false
          : (dpiStageAddStaging ?? this.dpiStageAddStaging),
      dpiStageRemoveLevelStaging: clearStaging
          ? null
          : (dpiStageRemoveLevelStaging ?? this.dpiStageRemoveLevelStaging),
      dpiStageLevelsStaging: clearStaging
          ? null
          : (dpiStageLevelsStaging ?? this.dpiStageLevelsStaging),
      dpiStageSaveInFlight: clearStaging
          ? false
          : (dpiStageSaveInFlight ?? this.dpiStageSaveInFlight),
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
      debounceStaging: clearStaging
          ? null
          : (debounceStaging ?? this.debounceStaging),
      sleepStaging: clearStaging
          ? null
          : (sleepStaging ?? this.sleepStaging),
      wheelInvertStaging: clearStaging
          ? null
          : (wheelInvertStaging ?? this.wheelInvertStaging),
      rgbEnableStaging: clearStaging
          ? null
          : (rgbEnableStaging ?? this.rgbEnableStaging),
      rgbModeIdStaging: clearStaging
          ? null
          : (rgbModeIdStaging ?? this.rgbModeIdStaging),
      rgbBrightnessStaging: clearStaging
          ? null
          : (rgbBrightnessStaging ?? this.rgbBrightnessStaging),
      rgbSpeedStaging: clearStaging
          ? null
          : (rgbSpeedStaging ?? this.rgbSpeedStaging),
      rgbRStaging: clearStaging ? null : (rgbRStaging ?? this.rgbRStaging),
      rgbGStaging: clearStaging ? null : (rgbGStaging ?? this.rgbGStaging),
      rgbBStaging: clearStaging ? null : (rgbBStaging ?? this.rgbBStaging),
      rgbSleepTimeStaging: clearStaging
          ? null
          : (rgbSleepTimeStaging ?? this.rgbSleepTimeStaging),
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
