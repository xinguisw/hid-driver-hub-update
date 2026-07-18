import 'package:driver_hub/layer1_discovery/settings_capabilities_pack.dart';
import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:driver_hub/layer3_ui/models/device_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('applyCapabilitiesToSettings seeds M7XSE matrix presence', () async {
    await DeviceCapabilityStore.load('m7xse');
    final caps = DeviceCapabilityStore.forDevice('aa4ecd01');
    expect(caps, isNotNull);

    final base = const DeviceSettingsState(
      devId: 'aa4ecd01',
      displayName: 'M7XSE',
      connectionMode: 0,
      loading: true,
    );
    final state = applyCapabilitiesToSettings(base, caps!);

    expect(state.reportRateOptions, [500, 250, 125]);
    expect(state.buttonCount, 6);
    expect(state.buttons, isNotNull);
    expect(state.buttons!.length, 6);
    expect(state.dpiMax, 5000);
    expect(state.dpiMaxLevels, 8);
    expect(state.dpiDefaultLevel, 2);
    expect(state.dpiRgbPerStage, isFalse);
    expect(state.dpiLevels, isNotNull);
    expect(state.dpiLevels!.length, 8);

    // M7XSE matrix: sensor features off; sleep on; rgb off.
    expect(state.hasSensorTuning, isFalse);
    expect(state.hasAngleTune, isFalse);
    expect(state.hasLod, isFalse);
    expect(state.hasPerformance, isFalse);
    expect(state.hasButtonDebounce, isFalse);
    expect(state.hasSleepTime, isTrue);
    expect(state.sleepOptionsSeconds, [900]);
    expect(state.hasWheelInvert, isFalse);
    expect(state.hasRgbBacklight, isFalse);
  });
}
