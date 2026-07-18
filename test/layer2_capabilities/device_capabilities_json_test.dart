import 'package:flutter_test/flutter_test.dart';
import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer2_capabilities/sensor_profiles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DeviceCapabilityStore loads m7xse.json from product matrix', () async {
    await DeviceCapabilityStore.load('m7xse');
    final caps = DeviceCapabilityStore.forDevice('aa4ecd01');
    expect(caps, isNotNull);
    expect(caps!.devId, 'aa4ecd01');
    expect(caps.displayNameKey, 'device.m7xse.name');
    expect(caps.buttons!.count, 6);
    expect(caps.buttons!.list.length, 6);
    expect(caps.buttons!.list.every((b) => b.remappable), isTrue);
    expect(caps.reportRate!.options, [500, 250, 125]);
    expect(caps.reportRate!.defaultValue, 500);
    expect(caps.dpi!.maxLevels, 8);
    expect(caps.dpi!.defaultLevel, 2);
    expect(caps.dpi!.maxDpi, 5000);
    expect(caps.dpi!.rgbPerStage, isFalse);
    expect(caps.dpi!.levels.length, 8);
    expect(caps.dpi!.levels.map((e) => e.value).toList(),
        [800, 1600, 2400, 3200, 5000, 1600, 1600, 1600]);
    expect(caps.sensor!.present, isFalse);
    expect(caps.sensor!.sensorTuning, isFalse);
    expect(caps.sensor!.angleTune, isFalse);
    expect(caps.sensor!.liftOffDistance!.present, isFalse);
    expect(caps.sensor!.liftOffDistance!.options, [1, 2, 3]);
    expect(caps.otherFeatures!.buttonDebounce!.present, isFalse);
    expect(caps.otherFeatures!.buttonDebounce!.options, [4, 8, 16, 24]);
    expect(caps.otherFeatures!.sleepTime!.present, isTrue);
    expect(caps.otherFeatures!.sleepTime!.options, [900]);
    expect(caps.otherFeatures!.wheelDirectionInvert, isFalse);
    expect(caps.rgbBacklight!.present, isFalse);
    expect(caps.rgbBacklight!.modes.length, 4);
    expect(caps.macro, isNull);
    expect(caps.osd!.enabled, isTrue);
    expect(DeviceCapabilityStore.forDevice('unknown'), isNull);
  });

  test('SensorProfiles loads PAW3311 for M7XSE; keeps SG8925 and PAW3395', () async {
    SensorProfiles.debugReset();
    await SensorProfiles.load();
    final usb = SensorProfiles.forDevice('aa4ecd01', 0);
    final rf = SensorProfiles.forDevice('aa4ecd01', 1);
    expect(usb, isNotNull);
    expect(rf, isNotNull);
    expect(usb!.chip, 'PAW3311');
    expect(rf!.chip, 'PAW3311');
    expect(usb.table, 'PAW3311/std');
    expect(rf.table, 'PAW3311/std');
    final paw3311 = SensorProfiles.table('PAW3311/std');
    expect(paw3311, isNotNull);
    expect(paw3311!.dpiEncoding.transform, 'paw3311');
    expect(paw3311.dpiEncoding.bytesPerAxis, 1);
    expect(paw3311.dpiEncoding.independentXY, isFalse);
    expect(paw3311.dpiEncoding.cpiMap[0x13], 840);
    expect(paw3311.dpiEncoding.cpiMap[0x26], 1200);
    expect(paw3311.dpiEncoding.cpiMap[0x39], 1620);
    expect(paw3311.dpiEncoding.cpiMap[0x55], 3180);
    final sigma = SensorProfiles.table('SG8925/std');
    expect(sigma, isNotNull);
    expect(sigma!.dpiEncoding.transform, 'identity');
    expect(sigma.dpiEncoding.bytesPerAxis, 2);
    expect(sigma.dpiRange.maxDpi, 5000);
    final paw = SensorProfiles.table('PAW3395/high_res');
    expect(paw, isNotNull);
    expect(paw!.dpiEncoding.factor, 50);
    expect(SensorProfiles.table('PAW3395/std_res')!.dpiEncoding.factor, 25);
  });
}

