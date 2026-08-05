import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';

sealed class DeviceSettingsEvent {
  const DeviceSettingsEvent();
}

class DeviceSettingsHydrated extends DeviceSettingsEvent {
  const DeviceSettingsHydrated(this.settings);

  final DeviceSettingsState settings;
}

/// Commits the factory-default button mapping immediately.
class DeviceSettingsResetButtonMappingRequested extends DeviceSettingsEvent {
  const DeviceSettingsResetButtonMappingRequested();
}

class DeviceSettingsSaveRequested extends DeviceSettingsEvent {
  const DeviceSettingsSaveRequested();
}

class DeviceSettingsCancelRequested extends DeviceSettingsEvent {
  const DeviceSettingsCancelRequested();
}

/// Navigation attempt with dirty sandbox (FR-OPS-005).
///
/// Per SDRD: allow navigation, dirty sweep silently (no modal).
class DeviceSettingsNavigationRequested extends DeviceSettingsEvent {
  const DeviceSettingsNavigationRequested();
}

/// User selected a catalog action for a button slot.
///
/// L3 passes only the catalog ID (e.g. `"mouse.left"`). L4 translates
/// to wire bytes via [ButtonActionCatalogMap].
class DeviceSettingsButtonMappingSlotRequested extends DeviceSettingsEvent {
  const DeviceSettingsButtonMappingSlotRequested({
    required this.buttonId,
    required this.catalogId,
  });

  /// 1-based physical button index.
  final int buttonId;

  /// L2 catalog action ID (e.g. `"mouse.left"`, `"key.letter.a"`).
  final String catalogId;
}

/// User selected a special combination (modifiers + key) for a button slot.
///
/// L3 passes modifier catalog IDs and the captured character. L4 translates
/// to wire bytes via [ButtonActionCatalogMap.buildComboSlot].
class DeviceSettingsSpecialComboRequested extends DeviceSettingsEvent {
  const DeviceSettingsSpecialComboRequested({
    required this.buttonId,
    required this.modifierIds,
    required this.keyChar,
  });

  /// 1-based physical button index.
  final int buttonId;

  /// Modifier catalog IDs (e.g. `["special.mod.ctrl", "special.mod.alt"]`).
  final List<String> modifierIds;

  /// Captured character (e.g. `"C"`).
  final String keyChar;
}

/// User selected a report rate value.
///
/// L3 passes the Hz value. L4 stages it and marks dirty.
class DeviceSettingsReportRateRequested extends DeviceSettingsEvent {
  const DeviceSettingsReportRateRequested({required this.hz});

  /// Selected polling rate in Hz (e.g. 125, 250, 500, 1000).
  final int hz;
}

/// Save report rate staging to device.
class DeviceSettingsSaveReportRateRequested extends DeviceSettingsEvent {
  const DeviceSettingsSaveReportRateRequested();
}

/// User selected a DPI level.
///
/// L3 passes the 1-based level (e.g. 1, 2, 3, ..., 8). L4 stages it and marks dirty.
class DeviceSettingsDpiLevelRequested extends DeviceSettingsEvent {
  const DeviceSettingsDpiLevelRequested({required this.level});

  /// Selected DPI level (1-based, e.g. 1, 2, 3, ..., 8).
  final int level;
}

/// Save DPI level staging to device.
class DeviceSettingsSaveDpiLevelRequested extends DeviceSettingsEvent {
  const DeviceSettingsSaveDpiLevelRequested();
}

/// User toggled ripple control.
///
/// L3 passes the boolean value. L4 stages it and marks dirty.
class DeviceSettingsRippleControlRequested extends DeviceSettingsEvent {
  const DeviceSettingsRippleControlRequested({required this.enabled});

  /// Whether ripple control is enabled.
  final bool enabled;
}

/// User toggled angle snap.
///
/// L3 passes the boolean value. L4 stages it and marks dirty.
class DeviceSettingsAngleSnapRequested extends DeviceSettingsEvent {
  const DeviceSettingsAngleSnapRequested({required this.enabled});

  /// Whether angle snap is enabled.
  final bool enabled;
}

/// Save sensor tuning staging to device.
class DeviceSettingsSaveSensorTuningRequested extends DeviceSettingsEvent {
  const DeviceSettingsSaveSensorTuningRequested();
}

/// User toggled angle tune enable/disable.
///
/// L3 passes the boolean value. L4 stages it and marks dirty.
class DeviceSettingsAngleTuneToggled extends DeviceSettingsEvent {
  const DeviceSettingsAngleTuneToggled({required this.enabled});

  /// Whether angle tune is enabled.
  final bool enabled;
}

/// User changed angle tune value (left/right arrow).
///
/// L3 passes the new wire value (index into the catalog options). L4 stages
/// it and marks dirty.
class DeviceSettingsAngleTuneValueChanged extends DeviceSettingsEvent {
  const DeviceSettingsAngleTuneValueChanged({required this.wireValue});

  /// Wire value (index into [AngleTuneCapabilities.options], e.g. 0-4).
  final int wireValue;
}

/// Save angle tune staging to device.
class DeviceSettingsSaveAngleTuneRequested extends DeviceSettingsEvent {
  const DeviceSettingsSaveAngleTuneRequested();
}

/// User selected an LOD value (radio button).
///
/// L3 passes the new wire value (index into catalog options). L4 stages it
/// and marks dirty.
class DeviceSettingsLodRequested extends DeviceSettingsEvent {
  const DeviceSettingsLodRequested({required this.wire});

  /// Wire value (index into [LiftOffDistance.options], e.g. 0-2).
  final int wire;
}

/// Save LOD staging to device.
class DeviceSettingsSaveLodRequested extends DeviceSettingsEvent {
  const DeviceSettingsSaveLodRequested();
}

/// User selected a performance mode (chip button).
///
/// L3 passes the new wire value (index into catalog options). L4 stages it
/// and marks dirty.
class DeviceSettingsPerformanceRequested extends DeviceSettingsEvent {
  const DeviceSettingsPerformanceRequested({required this.wire});

  /// Wire value (index into [SensorPerformance.options], e.g. 0-2).
  final int wire;
}

/// Save performance staging to device.
class DeviceSettingsSavePerformanceRequested extends DeviceSettingsEvent {
  const DeviceSettingsSavePerformanceRequested();
}

/// User selected a button debounce value (chip).
///
/// L3 passes the new wire index. L4 stages it and marks dirty.
class DeviceSettingsButtonDebounceRequested extends DeviceSettingsEvent {
  const DeviceSettingsButtonDebounceRequested({required this.wire});

  /// Wire index (into [ButtonDebounce.options], e.g. 0-6).
  final int wire;
}

/// Save button debounce staging to device.
class DeviceSettingsSaveButtonDebounceRequested extends DeviceSettingsEvent {
  const DeviceSettingsSaveButtonDebounceRequested();
}

/// User selected a sleep time value (chip).
///
/// L3 passes the new wire index. L4 stages it and marks dirty.
class DeviceSettingsSleepTimeRequested extends DeviceSettingsEvent {
  const DeviceSettingsSleepTimeRequested({required this.wire});

  /// Wire index (into [SleepTime.options], e.g. 0-6).
  final int wire;
}

/// Save sleep time staging to device.
class DeviceSettingsSaveSleepTimeRequested extends DeviceSettingsEvent {
  const DeviceSettingsSaveSleepTimeRequested();
}

/// User toggled wheel direction invert (chip or switch).
///
/// L3 passes the new bool. L4 stages it and marks dirty.
class DeviceSettingsWheelInvertRequested extends DeviceSettingsEvent {
  const DeviceSettingsWheelInvertRequested({required this.invert});

  /// Whether wheel direction is inverted.
  final bool invert;
}

/// Save wheel direction staging to device.
class DeviceSettingsSaveWheelInvertRequested extends DeviceSettingsEvent {
  const DeviceSettingsSaveWheelInvertRequested();
}
