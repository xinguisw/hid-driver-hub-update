/// Semantic background events that may be presented by a desktop OSD.
///
/// The model contains no HID bytes and no platform/window concepts. L4 owns
/// the conversion from device telemetry to these product-level labels; L3
/// decides how the labels are rendered.
class OsdPerformanceEvent {
  final String deviceId;
  final String? reportRateLabel;
  final int? reportRateHz;
  final int dpiLevel;
  final String dpiLabel;

  const OsdPerformanceEvent({
    required this.deviceId,
    required this.reportRateLabel,
    required this.reportRateHz,
    required this.dpiLevel,
    required this.dpiLabel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OsdPerformanceEvent &&
          deviceId == other.deviceId &&
          reportRateLabel == other.reportRateLabel &&
          reportRateHz == other.reportRateHz &&
          dpiLevel == other.dpiLevel &&
          dpiLabel == other.dpiLabel;

  @override
  int get hashCode =>
      Object.hash(deviceId, reportRateLabel, reportRateHz, dpiLevel, dpiLabel);
}

/// Semantic low-battery event for the desktop OSD.
///
/// L4 emits this once per physical-device low-battery episode; it contains no
/// protocol bytes or platform/window details.
class OsdBatteryLowEvent {
  final String deviceName;
  final int batteryPercent;
  final int thresholdPercent;

  const OsdBatteryLowEvent({
    required this.deviceName,
    required this.batteryPercent,
    required this.thresholdPercent,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OsdBatteryLowEvent &&
          deviceName == other.deviceName &&
          batteryPercent == other.batteryPercent &&
          thresholdPercent == other.thresholdPercent;

  @override
  int get hashCode => Object.hash(deviceName, batteryPercent, thresholdPercent);
}
