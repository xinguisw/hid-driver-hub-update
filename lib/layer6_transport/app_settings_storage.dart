import 'package:driver_hub/layer4_domain/app_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Platform-backed persistence for small global application settings.
///
/// The L4 repository boundary keeps this implementation replaceable without
/// changing UI or battery-alert orchestration.
class SharedPreferencesAppSettingsRepository implements AppSettingsRepository {
  SharedPreferencesAppSettingsRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _lowBatteryThresholdKey =
      'driver_hub.global_low_battery_threshold';

  final SharedPreferencesAsync _preferences;

  @override
  Future<int?> loadLowBatteryThreshold() =>
      _preferences.getInt(_lowBatteryThresholdKey);

  @override
  Future<void> saveLowBatteryThreshold(int threshold) =>
      _preferences.setInt(_lowBatteryThresholdKey, threshold);
}
