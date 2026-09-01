/// Per-physical-device low-battery notification state.
///
/// Emits when the battery level reaches or falls below the global threshold,
/// and re-emits on subsequent 10% milestone drops below the threshold
/// (e.g. at 20%, 10%, etc.). Charging or recovering above the threshold re-arms.
class LowBatteryAlertPolicy {
  // Map of devicePath to the last notified battery percentage
  final _lastWarnedPercent = <String, int>{};

  bool shouldNotify({
    required String devicePath,
    required int batteryPercent,
    required bool isCharging,
    required int thresholdPercent,
  }) {
    if (batteryPercent < 0) return false;
    final isLow = !isCharging && batteryPercent <= thresholdPercent;
    if (!isLow) {
      _lastWarnedPercent.remove(devicePath);
      return false;
    }

    final lastPercent = _lastWarnedPercent[devicePath];
    if (lastPercent == null) {
      // First time reaching or falling below threshold
      _lastWarnedPercent[devicePath] = batteryPercent;
      return true;
    }

    // Determine if we crossed a 10% milestone or dropped by >= 10% or reached <= 5% tier 0
    final lastTier = (lastPercent ~/ 10) * 10;
    final currentTier = (batteryPercent ~/ 10) * 10;

    // If battery drops across a 10% boundary or from 10% to 5% (tier 0)
    if (batteryPercent <= 5 && lastPercent > 5) {
      _lastWarnedPercent[devicePath] = batteryPercent;
      return true;
    }

    if (currentTier < lastTier && batteryPercent <= currentTier) {
      _lastWarnedPercent[devicePath] = batteryPercent;
      return true;
    }

    return false;
  }

  void removeDevice(String devicePath) {
    _lastWarnedPercent.remove(devicePath);
  }

  void clear() {
    _lastWarnedPercent.clear();
  }
}
