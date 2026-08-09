import 'package:driver_hub/layer2_capabilities/dpi_wire_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves the shared Telink B80 direct 16-bit profile', () {
    final profile = DpiWireProfiles.forKey('telink_b80_dpi16');

    expect(profile, same(DpiWireProfiles.telinkB80Dpi16));
    expect(profile!.bytesPerAxis, 2);
    expect(profile.endian, 'big');
    expect(profile.transform, 'identity');
    expect(profile.factor, 1);
  });

  test('unknown profile keys do not invent a wire encoding', () {
    expect(DpiWireProfiles.forKey('unknown'), isNull);
  });
}
