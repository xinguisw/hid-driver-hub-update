/// Shared L2 DPI wire parameters for Telink B80 C4.
/// Product-specific limits, stages, RGB, and XY behavior remain in each mouse JSON.
class DpiWireProfile {
  final String key;
  final String transform;
  final int factor;
  final int bytesPerAxis;
  final String endian;

  const DpiWireProfile({
    required this.key,
    required this.transform,
    required this.factor,
    required this.bytesPerAxis,
    required this.endian,
  });
}

/// Shared L2-owned DPI wire profiles.
class DpiWireProfiles {
  DpiWireProfiles._();

  static const telinkB80Dpi16 = DpiWireProfile(
    key: 'telink_b80_dpi16',
    transform: 'identity',
    factor: 1,
    bytesPerAxis: 2,
    endian: 'big',
  );

  static DpiWireProfile? forKey(String key) {
    switch (key) {
      case 'telink_b80_dpi16':
        return telinkB80Dpi16;
      default:
        return null;
    }
  }
}
