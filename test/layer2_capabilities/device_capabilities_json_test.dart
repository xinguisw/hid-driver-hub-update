import 'package:flutter_test/flutter_test.dart';
import 'package:driver_hub/layer2_capabilities/capabilities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DeviceCapabilityStore loads m7x_se.json from product matrix', () async {
    await DeviceCapabilityStore.load('M7X SE');
    final caps = DeviceCapabilityStore.forDevice('01_03');
    expect(caps, isNotNull);
    expect(caps!.devId, '01_03');
    expect(caps.displayNameKey, 'mouse.m7x_se.name');
    expect(caps.buttons!.count, 6);
    expect(caps.buttons!.list.length, 6);
    expect(caps.buttons!.list.every((b) => b.remappable), isTrue);
    expect(caps.reportRate!.options, [500, 250, 125]);
    expect(caps.reportRate!.defaultValue, 500);
    expect(caps.dpi!.maxLevels, 8);
    expect(caps.dpi!.activeLevelCount, 5);
    expect(caps.dpi!.defaultLevel, 2);
    expect(caps.dpi!.range.minDpi, 50);
    expect(caps.dpi!.range.maxDpi, 5000);
    expect(caps.dpi!.range.stepMode, 'fixed');
    expect(caps.dpi!.range.step, 50);
    expect(caps.dpi!.wireProfileKey, 'telink_b80_dpi16');
    expect(caps.sensor!.model, isNull);
    expect(caps.otherFeatures!.sleepTime!.defaultWire, 4);
    expect(caps.otherFeatures!.sleepTime!.options[4].label, '10 min');
    expect(caps.dpi!.rgbPerStage, isFalse);
    expect(caps.dpi!.levels.length, 8);
    expect(caps.dpi!.levels.map((e) => e.value).toList(), [
      800,
      1600,
      2400,
      3200,
      5000,
      1600,
      1600,
      1600,
    ]);
    expect(caps.sensor!.present, isTrue);
    expect(caps.sensor!.sensorTuning, isFalse);
    expect(caps.sensor!.angleTune, isFalse);
    expect(caps.sensor!.performance, isNotNull);
    expect(caps.sensor!.performance!.present, isFalse);
    expect(caps.sensor!.performance!.options, [0, 1, 2]);
    expect(caps.sensor!.liftOffDistance!.present, isFalse);
    expect(caps.sensor!.liftOffDistance!.options.length, 3);
    expect(caps.sensor!.liftOffDistance!.options[0].wire, 0);
    expect(caps.sensor!.liftOffDistance!.options[0].mm, 0.7);
    expect(caps.sensor!.liftOffDistance!.options[1].wire, 1);
    expect(caps.sensor!.liftOffDistance!.options[1].mm, 1.0);
    expect(caps.sensor!.liftOffDistance!.options[2].wire, 2);
    expect(caps.sensor!.liftOffDistance!.options[2].mm, 2.0);
    expect(caps.otherFeatures!.buttonDebounce!.present, isFalse);
    expect(caps.otherFeatures!.buttonDebounce!.options.length, 6);
    expect(caps.otherFeatures!.buttonDebounce!.options[0].wire, 0);
    expect(caps.otherFeatures!.buttonDebounce!.options[0].label, '2ms');
    expect(caps.otherFeatures!.buttonDebounce!.options[4].wire, 4);
    expect(caps.otherFeatures!.buttonDebounce!.options[4].label, '10ms');
    expect(caps.otherFeatures!.sleepTime!.present, isTrue);
    expect(caps.otherFeatures!.sleepTime!.options.length, 7);
    expect(caps.otherFeatures!.sleepTime!.options[0].wire, 0);
    expect(caps.otherFeatures!.sleepTime!.options[0].label, '30 sec');
    expect(caps.otherFeatures!.sleepTime!.options[5].wire, 5);
    expect(caps.otherFeatures!.sleepTime!.options[5].label, '15 min');
    expect(caps.otherFeatures!.wheelDirectionInvert, isFalse);
    expect(caps.rgbBacklight!.present, isFalse);
    expect(caps.rgbBacklight!.modes.length, 8);
    expect(caps.rgbBacklight!.sleepTimeOptions.length, 7);
    expect(caps.macro, isNotNull);
    expect(caps.macro!.slots, 16);
    expect(caps.macro!.maxLength, 30);
    expect(caps.osd!.enabled, isTrue);
    expect(DeviceCapabilityStore.forDevice('unknown'), isNull);
  });

  test(
    'DeviceCapabilityStore loads m7x.json (M7X, PAW3311, DPI RGB)',
    () async {
      await DeviceCapabilityStore.load('m7x');
      final caps = DeviceCapabilityStore.forDevice('01_02');
      expect(caps, isNotNull);
      expect(caps!.devId, '01_02');
      expect(caps.displayNameKey, 'device.m7x.name');
      expect(caps.reportRate!.options, [1000, 500, 250, 125]);
      expect(caps.dpi!.range.maxDpi, 12000);
      expect(caps.dpi!.range.stepMode, 'tiered');
      expect(caps.dpi!.range.tiers!.length, 2);
      expect(caps.dpi!.range.tiers![0].max, 10000);
      expect(caps.dpi!.range.tiers![0].step, 50);
      expect(caps.dpi!.range.tiers![1].max, 12000);
      expect(caps.dpi!.range.tiers![1].step, 100);
      expect(caps.dpi!.rgbPerStage, isTrue);
      expect(caps.sensor!.sensorTuning, isTrue);
      expect(caps.sensor!.angleTune, isFalse);
      expect(caps.sensor!.liftOffDistance!.present, isFalse);
      expect(caps.otherFeatures!.sleepTime!.present, isTrue);
      expect(caps.macro!.slots, 16);
      expect(caps.macro!.maxLength, 30);
      expect(caps.rgbBacklight!.present, isFalse);
    },
  );

  test(
    'DeviceCapabilityStore loads m7x_pro.json (M7X PRO, PAW3395, backlight)',
    () async {
      await DeviceCapabilityStore.load('m7x pro');
      final caps = DeviceCapabilityStore.forDevice('01_01');
      expect(caps, isNotNull);
      expect(caps!.devId, '01_01');
      expect(caps.displayNameKey, 'device.m7x_pro.name');
      expect(caps.reportRate!.options, [1000, 500, 250, 125]);
      expect(caps.dpi!.range.maxDpi, 24000);
      expect(caps.dpi!.range.stepMode, 'fixed');
      expect(caps.dpi!.range.step, 50);
      expect(caps.dpi!.rgbPerStage, isTrue);
      expect(caps.sensor!.sensorTuning, isTrue);
      expect(caps.sensor!.angleTune, isTrue);
      expect(caps.sensor!.angleTuneDetails!.options!.length, 5);
      expect(caps.sensor!.liftOffDistance!.present, isTrue);
      expect(caps.sensor!.liftOffDistance!.options.length, 2);
      expect(caps.macro!.slots, 16);
      expect(caps.macro!.maxLength, 30);
      expect(caps.rgbBacklight!.present, isTrue);
      expect(caps.rgbBacklight!.modes.length, 8);
      expect(caps.rgbBacklight!.sleepTimeOptions.length, 7);
    },
  );

  test(
    'all mouse capabilities use the shared Telink B80 DPI profile',
    () async {
      for (final model in ['m7x se', 'm7x', 'm7x pro']) {
        await DeviceCapabilityStore.load(model);
      }
      for (final devId in ['01_03', '01_02', '01_01']) {
        final caps = DeviceCapabilityStore.forDevice(devId);
        expect(caps, isNotNull);
        expect(caps!.macro, isNotNull);
        expect(caps.macro!.slots, 16);
        expect(caps.macro!.maxLength, 30);
        expect(caps.dpi!.activeLevelCount, 5);
        expect(caps.otherFeatures!.sleepTime!.defaultWire, 4);
        expect(caps.dpi!.wireProfileKey, 'telink_b80_dpi16');
        expect(caps.dpi!.wireProfile, isNotNull);
        expect(caps.dpi!.wireProfile!.bytesPerAxis, 2);
        expect(caps.dpi!.wireProfile!.endian, 'big');
        expect(caps.dpi!.wireProfile!.transform, 'identity');
      }
    },
  );

  test('all three mouse catalogs use valid left/right hotspots', () async {
    for (final model in ['m7x se', 'm7x', 'm7x pro']) {
      await DeviceCapabilityStore.load(model);
    }

    for (final devId in ['01_03', '01_02', '01_01']) {
      final caps = DeviceCapabilityStore.forDevice(devId);
      expect(caps, isNotNull);
      final buttons = caps!.buttons!.list;

      expect(buttons[0].hotspot.x, 0.39);
      expect(buttons[0].hotspot.y, 0.21);
      expect(buttons[1].hotspot.x, 0.64);
      expect(buttons[1].hotspot.y, 0.21);
    }
  });
}
