/// Per-physical-device low-battery notification state.
///
/// Emits once while a device remains at or below the global threshold. A
/// charging report or a level above the threshold re-arms a later low episode.
class LowBatteryAlertPolicy {
  final _warnedPaths = <String>{};

  bool shouldNotify({
    required String devicePath,
    required int batteryPercent,
    required bool isCharging,
    required int thresholdPercent,
  }) {
    if (batteryPercent < 0) return false;
    final isLow = !isCharging && batteryPercent <= thresholdPercent;
    if (!isLow) {
      _warnedPaths.remove(devicePath);
      return false;
    }
    return _warnedPaths.add(devicePath);
  }

  void removeDevice(String devicePath) {
    _warnedPaths.remove(devicePath);
  }

  void clear() {
    _warnedPaths.clear();
  }
}
