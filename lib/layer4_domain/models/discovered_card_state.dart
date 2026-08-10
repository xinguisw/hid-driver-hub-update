/// View model for the mouse card. Pure data — no behavior, no HID, no rendering.
///
/// Carries what the card and the future canvas need. The session (tier 2)
/// gathers the fields from catalog + protocol and packs them here; the card
/// (tier 1) consumes them. This keeps session and UI decoupled.
///
/// [batteryPercentage] below 0 → card shows "Battery —" (soft battery / unknown).
/// Empty firmware labels → "—".
class DiscoveredCardState {
  final String devId;
  final String displayName;
  final int connectionMode; // 0=USB, 1=2.4G
  /// Mouse firmware for the device card. Kept for existing card consumers.
  final String firmwareVersion;

  /// Mouse firmware shown in Device Setting alongside the receiver firmware.
  final String mouseFirmwareVersion;

  /// Dongle firmware shown in Device Setting. Empty on query failure.
  final String dongleFirmwareVersion;

  /// Stable non-HID key used by L4 to bind this card to its device gateway.
  final String deviceKey;

  /// 0..100, or -1 when unknown (A4 failed; may update via OSD/poll).
  final int batteryPercentage;
  final bool isCharging;
  final dynamic physicalHandle; // raw HID handle, for identity — not rendered

  /// Small image asset path — used by the card.
  final String imageSmall;

  /// Large image asset path — used by the future canvas, not the card.
  final String imageLarge;

  const DiscoveredCardState({
    required this.devId,
    required this.displayName,
    required this.connectionMode,
    required this.firmwareVersion,
    this.mouseFirmwareVersion = '',
    this.dongleFirmwareVersion = '',
    this.deviceKey = '',
    required this.batteryPercentage,
    required this.isCharging,
    required this.physicalHandle,
    required this.imageSmall,
    required this.imageLarge,
  });

  DiscoveredCardState copyWith({
    String? devId,
    String? displayName,
    int? connectionMode,
    String? firmwareVersion,
    String? mouseFirmwareVersion,
    String? dongleFirmwareVersion,
    String? deviceKey,
    int? batteryPercentage,
    bool? isCharging,
    dynamic physicalHandle,
    String? imageSmall,
    String? imageLarge,
  }) {
    return DiscoveredCardState(
      devId: devId ?? this.devId,
      displayName: displayName ?? this.displayName,
      connectionMode: connectionMode ?? this.connectionMode,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      mouseFirmwareVersion: mouseFirmwareVersion ?? this.mouseFirmwareVersion,
      dongleFirmwareVersion:
          dongleFirmwareVersion ?? this.dongleFirmwareVersion,
      deviceKey: deviceKey ?? this.deviceKey,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      isCharging: isCharging ?? this.isCharging,
      physicalHandle: physicalHandle ?? this.physicalHandle,
      imageSmall: imageSmall ?? this.imageSmall,
      imageLarge: imageLarge ?? this.imageLarge,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredCardState &&
          runtimeType == other.runtimeType &&
          devId == other.devId &&
          displayName == other.displayName &&
          connectionMode == other.connectionMode &&
          firmwareVersion == other.firmwareVersion &&
          mouseFirmwareVersion == other.mouseFirmwareVersion &&
          dongleFirmwareVersion == other.dongleFirmwareVersion &&
          deviceKey == other.deviceKey &&
          batteryPercentage == other.batteryPercentage &&
          isCharging == other.isCharging &&
          physicalHandle == other.physicalHandle &&
          imageSmall == other.imageSmall &&
          imageLarge == other.imageLarge;

  @override
  int get hashCode =>
      devId.hashCode ^
      displayName.hashCode ^
      connectionMode.hashCode ^
      firmwareVersion.hashCode ^
      mouseFirmwareVersion.hashCode ^
      dongleFirmwareVersion.hashCode ^
      deviceKey.hashCode ^
      batteryPercentage.hashCode ^
      isCharging.hashCode ^
      physicalHandle.hashCode ^
      imageSmall.hashCode ^
      imageLarge.hashCode;
}
