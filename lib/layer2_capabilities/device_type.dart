/// Kind of peripheral a device reports as, on the wire and in the catalog.
///
/// Lives in the device-descriptor layer (tier 3): both the catalog
/// ([DeviceCatalogEntry.deviceType]) and the handshake result
/// ([DeviceHandshake.deviceType]) speak this type, so the session's verify
/// step compares like for like instead of bare ints.
///
/// Codes match the firmware's device-type byte. Only [mouse] is verified
/// against hardware; add a value (with its code) when a device of that kind
/// gets a catalog entry, and the code MUST match what the handshake reports.
enum DeviceType {
  mouse(1);

  final int code;
  const DeviceType(this.code);

  /// Parses a wire/catalog [code]. Returns null for an unknown type so the
  /// verify step rejects (rather than errors on) an unsupported device.
  static DeviceType? fromCode(int code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }

  /// Parses a catalog [code], throwing on unknown. Catalog data is authored,
  /// so an unknown type there is a data error worth surfacing at load time.
  static DeviceType fromCatalogCode(int code) {
    final t = fromCode(code);
    if (t == null) {
      throw FormatException('Unknown deviceType code: $code');
    }
    return t;
  }
}
