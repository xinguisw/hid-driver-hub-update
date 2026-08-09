/// L4 boundary for global application settings.
///
/// The domain owns the meaning and validation of a setting; the storage
/// implementation remains replaceable in L6 (for example, by Hive later).
abstract interface class AppSettingsRepository {
  Future<int?> loadLowBatteryThreshold();

  Future<void> saveLowBatteryThreshold(int threshold);
}
