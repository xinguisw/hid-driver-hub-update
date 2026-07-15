import 'package:flutter_test/flutter_test.dart';
import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer2_capabilities/sensor_profiles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DeviceCapabilityStore loads aa4ecd01 from JSON with same fields', () async {
    await DeviceCapabilityStore.load();
    final caps = DeviceCapabilityStore.forDevice('aa4ecd01');
    expect(caps, isNotNull);
    expect(caps!.devId, 'aa4ecd01');
    expect(caps.displayNameKey, 'device.m7xse.name');
    expect(caps.buttons!.count, 6);
    expect(caps.buttons!.list.length, 6);
    expect(caps.buttons!.list[0].id, 1);
    expect(caps.buttons!.list[0].remappable, false);
    expect(caps.buttons!.list[0].hotspot.x, 0.22);
    expect(caps.reportRate!.options, [125, 500, 1000, 4000]);
    expect(caps.reportRate!.defaultValue, 1000);
    expect(caps.dpi!.maxLevels, 8);
    expect(caps.dpi!.defaultLevel, 1);
    expect(caps.dpi!.maxDpi, 3200);
    expect(caps.dpi!.independentXY, false);
    expect(caps.dpi!.rgbPerStage, true);
    expect(caps.dpi!.levels.length, 3);
    expect(caps.dpi!.levels[0].value, 400);
    expect(caps.dpi!.levels[0].color, '#FF0000');
    expect(caps.sensor!.present, true);
    expect(caps.sensor!.sensorTuning, true);
    expect(caps.sensor!.angleTune, false);
    expect(caps.sensor!.liftOffDistance!.options, [1, 2, 3]);
    expect(caps.otherFeatures!.wheelDirectionInvert, true);
    expect(caps.otherFeatures!.buttonDebounce!.options, [4, 8, 16, 24]);
    expect(caps.otherFeatures!.sleepTime!.options, [30, 60, 300, 600]);
    expect(caps.rgbBacklight!.present, true);
    expect(caps.rgbBacklight!.modes.length, 4);
    expect(caps.rgbBacklight!.brightnessLevels, 5);
    expect(caps.macro!.slots, 16);
    expect(caps.macro!.maxLength, 127);
    expect(caps.osd!.enabled, true);
    expect(DeviceCapabilityStore.forDevice('unknown'), isNull);
  });

  test('SensorProfiles loads tables and aa4ecd01:1 from JSON', () async {
    await SensorProfiles.load();
    final profile = SensorProfiles.forDevice('aa4ecd01', 1);
    expect(profile, isNotNull);
    expect(profile!.chip, 'PAW3395');
    expect(profile.mode, 'high_res');
    expect(profile.table, 'PAW3395/high_res');
    final table = SensorProfiles.table('PAW3395/high_res');
    expect(table, isNotNull);
    expect(table!.dpiEncoding.factor, 50);
    expect(table.dpiRange.maxDpi, 26000);
    final std = SensorProfiles.table('PAW3395/std_res');
    expect(std!.dpiEncoding.factor, 25);
    expect(std.dpiRange.maxDpi, 16000);
    expect(SensorProfiles.forDevice('aa4ecd01', 0), isNull);
  });
}
