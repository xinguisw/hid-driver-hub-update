import 'package:driver_hub/layer4_domain/bloc/device_settings_bloc.dart';
import 'package:driver_hub/layer4_domain/bloc/device_settings_event.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macro mapping stages action 0x14 with the selected slot', () async {
    const settings = DeviceSettingsState(
      devId: '03AA',
      displayName: 'M7X PRO',
      connectionMode: 0,
      loading: false,
      buttonCount: 6,
      buttons: [
        ButtonData(id: 1, labelKey: 'b1', remappable: true, action: 2),
        ButtonData(id: 2, labelKey: 'b2', remappable: true, action: 3),
        ButtonData(id: 3, labelKey: 'b3', remappable: true, action: 4),
        ButtonData(id: 4, labelKey: 'b4', remappable: true, action: 5),
        ButtonData(id: 5, labelKey: 'b5', remappable: true, action: 6),
        ButtonData(id: 6, labelKey: 'b6', remappable: true, action: 0x0E),
      ],
    );
    final bloc = DeviceSettingsBloc(
      commitButtonMapping: (_) async {},
      commitReportRate: (_) async {},
      commitDpiLevel: (_) async {},
      commitDpiValues: (_) async {},
      commitDpiStages: (_, _) async {},
      commitSensorTuning: (_, _) async {},
      commitAngleTune: (_) async {},
      commitLod: (_) async {},
      commitPerformance: (_) async {},
      commitDebounce: (_) async {},
      commitSleep: (_) async {},
      commitWheelInvert: (_) async {},
      commitRgbBacklight: (_) async {},
    );
    bloc.add(const DeviceSettingsHydrated(settings));
    await pumpEventQueue();
    bloc.add(const DeviceSettingsMacroMappingRequested(buttonId: 2, macroSlot: 7));
    await pumpEventQueue();

    expect(bloc.state.buttonMappingStaging?[1].action, 0x14);
    expect(bloc.state.buttonMappingStaging?[1].param1, 7);
    expect(bloc.state.isDirty, true);
    await bloc.close();
  });
}
