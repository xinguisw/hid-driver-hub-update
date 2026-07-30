import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';

sealed class DeviceSettingsEvent {
  const DeviceSettingsEvent();
}

class DeviceSettingsHydrated extends DeviceSettingsEvent {
  const DeviceSettingsHydrated(this.settings);

  final DeviceSettingsState settings;
}

/// Stages identity button map (sandbox only).
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
