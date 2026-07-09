/// View model for the mouse card. Pure data — no behavior, no HID, no rendering.
///
/// Carries what the card and the future canvas need. The session (tier 2)
/// gathers the fields from catalog + protocol and packs them here; the card
/// (tier 1) consumes them. This keeps session and UI decoupled.
///
/// Protocol-dependent fields are placeholders, wired later:
/// - [firmwareVersion], [batteryPercentage], [isCharging] — TODO, need the
///   firmware query (opcode A8) and the OSD push protocol. Until then they
///   carry sentinel values; the card renders them as "—".
class DiscoveredCardState {
  final String devId;
  final String displayName;
  final int connectionMode; // 0=USB, 1=2.4G
  final String firmwareVersion;
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
      batteryPercentage.hashCode ^
      isCharging.hashCode ^
      physicalHandle.hashCode ^
      imageSmall.hashCode ^
      imageLarge.hashCode;
}
