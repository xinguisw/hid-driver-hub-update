import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';

/// L4 BLoC events — chart "Dispatch Event to BLoC Controller".
///
/// L3 only adds these; never stages or talks to L5 itself.
sealed class DeviceSettingsEvent {
  const DeviceSettingsEvent();
}

/// Seed / replace synced profile after onboard hydrate (or cache hit).
class DeviceSettingsHydrated extends DeviceSettingsEvent {
  const DeviceSettingsHydrated(this.settings);

  final DeviceSettingsState settings;
}

/// User Confirm on Reset tip — chart "User adjusts setting".
///
/// Stages identity defaults only; does **not** encode. Follow with
/// [DeviceSettingsSaveRequested] (explicit Save UI or auto-Save).
class DeviceSettingsResetButtonMappingRequested extends DeviceSettingsEvent {
  const DeviceSettingsResetButtonMappingRequested();
}

/// Chart "Click save?" Yes → validate → payload → L5.
class DeviceSettingsSaveRequested extends DeviceSettingsEvent {
  const DeviceSettingsSaveRequested();
}

/// Chart "Click cancel?" → wipe staging, revert to last synchronized.
class DeviceSettingsCancelRequested extends DeviceSettingsEvent {
  const DeviceSettingsCancelRequested();
}
