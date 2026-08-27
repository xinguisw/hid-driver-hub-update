/// Per-physical-device low-battery notification state.
///
/// Emits when the battery level reaches or falls below the global threshold,
/// and re-emits on subsequent 10% milestone drops below the threshold
/// (e.g. at 20%, 10%, etc.). Charging or recovering above the threshold re-arms.
class LowBatteryAlertPolicy {
  // Map of devicePath to the last notified battery tier (or last notified percentage)
  final _lastWarnedTier = <String, int>{};

  bool shouldNotify({
    required String devicePath,
    required int batteryPercent,
    required bool isCharging,
    required int thresholdPercent,
  }) {
    if (batteryPercent < 0) return false;
    final isLow = !isCharging && batteryPercent <= thresholdPercent;
    if (!isLow) {
      _lastWarnedTier.remove(devicePath);
      return false;
    }

    // Determine current 10% tier (e.g. 20% -> tier 20, 19%..10% -> tier 10, 9%..0% -> tier 0)
    // Or milestone drop: (batteryPercent ~/ 10) * 10
    final currentTier = (batteryPercent ~/ 10) * 10;
    final lastTier = _lastWarnedTier[devicePath];

    if (lastTier == null) {
      // First time reaching/falling below threshold
      _lastWarnedTier[devicePath] = currentTier;
      return true;
    } else if (currentTier < lastTier) {
      // Crossed another 10% boundary downwards
      _lastWarnedTier[devicePath] = currentTier;
      return true;
    }

    return false;
  }

  void removeDevice(String devicePath) {
    _lastWarnedTier.remove(devicePath);
  }

  void clear() {
    _lastWarnedTier.clear();
  }
}
