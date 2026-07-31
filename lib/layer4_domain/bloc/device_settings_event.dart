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
